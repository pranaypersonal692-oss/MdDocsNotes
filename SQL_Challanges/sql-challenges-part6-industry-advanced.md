# SQL Challenges - Part 6: Industry Advanced Topics

**Difficulty Range:** 🔴 Hard to 🔥 Expert  
**Total Challenges:** 12  
**Topics Covered:** Recursive Queries, Advanced Analytics, Query Optimization, Real-world Scenarios, Production Patterns

**Database:** All challenges use `sql-practice-database.sql` (company_db)

---

## Challenge 1: Recursive Bill of Materials 🔥

**Difficulty:** Expert  
**Topic:** Recursive CTEs for hierarchical data

### Problem
Use the bill_of_materials table to find all components needed to build a LAPTOP-PRO, including sub-components at all levels.

### Solution
```sql
WITH RECURSIVE bom_explosion AS (
    -- Base case: top-level components
    SELECT 
        1 AS level,
        component_id,
        part_id,
        quantity,
        quantity AS total_quantity,
        component_id || ' -> ' || part_id AS path
    FROM bill_of_materials
    WHERE component_id = 'LAPTOP-PRO'
    
    UNION ALL
    
    -- Recursive case: sub-components
    SELECT 
        be.level + 1,
        bom.component_id,
        bom.part_id,
        bom.quantity,
        be.total_quantity * bom.quantity AS total_quantity,
        be.path || ' -> ' || bom.part_id
    FROM bill_of_materials bom
    INNER JOIN bom_explosion be ON bom.component_id = be.part_id
)
SELECT level, component_id, part_id, quantity, total_quantity, path
FROM bom_explosion
ORDER BY level, component_id;

-- Summary: Total parts needed
SELECT part_id, SUM(total_quantity) AS total_needed
FROM bom_explosion
GROUP BY part_id;
```

### Key Concepts
- Recursive CTE for tree traversal, Hierarchical data explosion, Path tracking, Manufacturing applications

---

## Challenge 2: Finding Shortest Path (Graph Traversal) 🔥

**Difficulty:** Expert  
**Topic:** Recursive CTEs for graph problems

### Problem
Find the shortest flight path from SFO to JFK using the flights table.

### Solution
```sql
WITH RECURSIVE flight_paths AS (
    -- Base case: flights from SFO
    SELECT 
        flight_id,
        origin,
        destination,
        distance,
        price,
        1 AS hop_count,
        origin || ' -> ' || destination AS path,
        ARRAY[origin, destination] AS visited
    FROM flights
    WHERE origin = 'SFO'
    
    UNION ALL
    
    -- Recursive case: continue journey
    SELECT 
        f.flight_id,
        f.origin,
        f.destination,
        fp.distance + f.distance,
        fp.price + f.price,
        fp.hop_count + 1,
        fp.path || ' -> ' || f.destination,
        fp.visited || f.destination
    FROM flights f
    INNER JOIN flight_paths fp ON f.origin = fp.destination
    WHERE f.destination != ALL(fp.visited)  -- Prevent cycles
        AND fp.hop_count < 5  -- Limit depth
)
SELECT path, distance AS total_distance, price AS total_cost, hop_count
FROM flight_paths
WHERE destination = 'JFK'
ORDER BY distance ASC
LIMIT 5;
```

### Key Concepts
- Graph traversal, Cycle prevention, Shortest path algorithms, Route optimization

---

## Challenge 3: Gap and Island Detection 🔴

**Difficulty:** Hard  
**Topic:** Finding sequences and gaps

### Problem
Find gaps in order numbers (missing order IDs) and identify continuous sequences ("islands").

### Solution
```sql
-- Find gaps
WITH order_sequence AS (
    SELECT 
        order_id,
        LAG(order_id) OVER (ORDER BY order_id) AS previous_id
    FROM orders
)
SELECT 
    previous_id + 1 AS gap_start,
    order_id - 1 AS gap_end,
    order_id - previous_id - 1 AS missing_count
FROM order_sequence
WHERE order_id - previous_id > 1;

-- Find islands (continuous sequences)
WITH order_groups AS (
    SELECT 
        order_id,
        order_id - ROW_NUMBER() OVER (ORDER BY order_id) AS group_id
    FROM orders
)
SELECT 
    MIN(order_id) AS island_start,
    MAX(order_id) AS island_end,
    COUNT(*) AS island_size
FROM order_groups
GROUP BY group_id;
```

### Key Concepts
- Gap and island problems, Window functions for sequence analysis, Data quality checks

---

## Challenge 4: Running Total with Reset 🔴

**Difficulty:** Hard  
**Topic:** Conditional window functions

### Problem
Calculate running total of order amounts per customer, but reset when customer changes tier.

### Solution
```sql
WITH customer_events AS (
    SELECT 
        o.order_id,
        o.customer_id,
        c.tier,
        o.order_date,
        o.total,
        LAG(c.tier) OVER (PARTITION BY o.customer_id ORDER BY o.order_date) AS prev_tier,
        CASE 
            WHEN LAG(c.tier) OVER (PARTITION BY o.customer_id ORDER BY o.order_date) != c.tier 
            THEN 1 ELSE 0 
        END AS tier_changed
    FROM orders o
    INNER JOIN customers c ON o.customer_id = c.customer_id
),
with_groups AS (
    SELECT *, SUM(tier_changed) OVER (PARTITION BY customer_id ORDER BY order_date) AS tier_group
    FROM customer_events
)
SELECT 
    customer_id,
    tier,
    order_date,
    total,
    SUM(total) OVER (PARTITION BY customer_id, tier_group ORDER BY order_date) AS running_total_in_tier
FROM with_groups;
```

### Key Concepts
- Conditional running totals, State change detection, Cumulative grouping

---

## Challenge 5: Cohort Analysis 🔥

**Difficulty:** Expert  
**Topic:** Customer cohort retention analysis

### Problem
Analyze customer retention by monthly cohorts showing percentages of customers making purchases in subsequent months.

### Solution
```sql
WITH customer_cohorts AS (
    SELECT customer_id, DATE_TRUNC('month', MIN(order_date)) AS cohort_month
    FROM orders
    GROUP BY customer_id
),
customer_activities AS (
    SELECT 
        cc.cohort_month,
        cc.customer_id,
        DATE_TRUNC('month', o.order_date) AS activity_month,
        EXTRACT(YEAR FROM AGE(o.order_date, cc.cohort_month)) * 12 + 
        EXTRACT(MONTH FROM AGE(o.order_date, cc.cohort_month)) AS months_since_cohort
    FROM customer_cohorts cc
    INNER JOIN orders o ON cc.customer_id = o.customer_id
),
cohort_sizes AS (
    SELECT cohort_month, COUNT(DISTINCT customer_id) AS cohort_size
    FROM customer_cohorts
    GROUP BY cohort_month
),
retention_data AS (
    SELECT 
        ca.cohort_month,
        ca.months_since_cohort,
        COUNT(DISTINCT ca.customer_id) AS active_customers
    FROM customer_activities ca
    GROUP BY ca.cohort_month, ca.months_since_cohort
)
SELECT 
    rd.cohort_month,
    cs.cohort_size,
    MAX(CASE WHEN rd.months_since_cohort = 0 THEN ROUND(100.0 * rd.active_customers / cs.cohort_size, 1) END) AS month_0,
    MAX(CASE WHEN rd.months_since_cohort = 1 THEN ROUND(100.0 * rd.active_customers / cs.cohort_size, 1) END) AS month_1,
    MAX(CASE WHEN rd.months_since_cohort = 2 THEN ROUND(100.0 * rd.active_customers / cs.cohort_size, 1) END) AS month_2
FROM retention_data rd
INNER JOIN cohort_sizes cs ON rd.cohort_month = cs.cohort_month
GROUP BY rd.cohort_month, cs.cohort_size;
```

### Key Concepts
- Cohort analysis, Retention metrics, Pivot table creation

---

## Challenge 6: RFM Segmentation 🔴

**Difficulty:** Hard  
**Topic:** Customer segmentation with RFM

### Problem
Segment customers using RFM (Recency, Frequency, Monetary) analysis.

### Solution
```sql
WITH customer_rfm AS (
    SELECT 
        c.customer_id,
        c.customer_name,
        CURRENT_DATE - MAX(o.order_date) AS days_since_last_order,
        COUNT(o.order_id) AS order_count,
        SUM(o.total) AS total_spent
    FROM customers c
    LEFT JOIN orders o ON c.customer_id = o.customer_id
    WHERE c.status = 'ACTIVE'
    GROUP BY c.customer_id, c.customer_name
),
rfm_scores AS (
    SELECT 
        *,
        NTILE(5) OVER (ORDER BY days_since_last_order ASC) AS recency_score,
        NTILE(5) OVER (ORDER BY order_count DESC) AS frequency_score,
        NTILE(5) OVER (ORDER BY total_spent DESC) AS monetary_score
    FROM customer_rfm
)
SELECT 
    customer_name,
   days_since_last_order,
    order_count,
    ROUND(total_spent, 2) AS total_spent,
    recency_score,
    frequency_score,
    monetary_score,
    CASE
        WHEN recency_score >= 4 AND frequency_score >= 4 AND monetary_score >= 4 THEN 'Champions'
        WHEN recency_score >= 3 AND frequency_score >= 3 AND monetary_score >= 3 THEN 'Loyal'
        WHEN recency_score >= 4 AND frequency_score <= 2 THEN 'Potential'
        WHEN recency_score <= 2 AND frequency_score >= 4 THEN 'At Risk'
        ELSE 'Need Attention'
    END AS rfm_segment
FROM rfm_scores;
```

### Key Concepts
- RFM analysis, Customer segmentation, NTILE for quintiles, Marketing analytics

---

## Challenge 7: Identifying Duplicate Records 🔴

**Difficulty:** Hard  
**Topic:** Finding and handling duplicates

### Problem
Find duplicate customers based on similar names or emails (fuzzy matching).

### Solution
```sql
-- Find exact duplicates on normalized email
WITH normalized_customers AS (
    SELECT 
        customer_id,
        customer_name,
        email,
        LOWER(TRIM(email)) AS normalized_email,
        LOWER(REGEXP_REPLACE(customer_name, '\s+', ' ', 'g')) AS normalized_name
    FROM customers
),
duplicates AS (
    SELECT 
        nc.*,
        CASE 
            WHEN COUNT(*) OVER (PARTITION BY normalized_email) > 1 THEN 'EMAIL'
            WHEN COUNT(*) OVER (PARTITION BY normalized_name) > 1 THEN 'NAME'
            ELSE NULL
        END AS duplicate_type,
        DENSE_RANK() OVER (PARTITION BY normalized_email ORDER BY customer_id) AS group_id
    FROM normalized_customers nc
)
SELECT customer_id, customer_name, email, duplicate_type
FROM duplicates
WHERE duplicate_type IS NOT NULL
ORDER BY group_id, customer_id;
```

### Key Concepts
- Duplicate detection, String normalization, Fuzzy matching, Data quality

---

## Challenge 8: Time-Series Moving Averages 🔴

**Difficulty:** Hard  
**Topic:** Advanced time-series analysis

### Problem
Calculate 7-day, 30-day moving averages for daily sales with trend indicators.

### Solution
```sql
WITH daily_sales AS (
    SELECT 
        DATE_TRUNC('day', order_date) AS sale_date,
        SUM(total) AS daily_revenue,
        COUNT(*) AS order_count
    FROM orders
    GROUP BY DATE_TRUNC('day', order_date)
),
sales_with_ma AS (
    SELECT 
        sale_date,
        daily_revenue,
        ROUND(AVG(daily_revenue) OVER (ORDER BY sale_date ROWS BETWEEN 6 PRECEDING AND CURRENT ROW), 2) AS ma_7day,
        ROUND(AVG(daily_revenue) OVER (ORDER BY sale_date ROWS BETWEEN 29 PRECEDING AND CURRENT ROW), 2) AS ma_30day,
        ROUND(STDDEV(daily_revenue) OVER (ORDER BY sale_date ROWS BETWEEN 29 PRECEDING AND CURRENT ROW), 2) AS stddev_30day
    FROM daily_sales
)
SELECT 
    sale_date,
    daily_revenue,
    ma_7day,
    ma_30day,
    CASE 
        WHEN daily_revenue > ma_30day + stddev_30day THEN 'SPIKE ↑'
        WHEN daily_revenue < ma_30day - stddev_30day THEN 'DIP ↓'
        WHEN daily_revenue > ma_7day THEN 'UP →'
        ELSE 'STABLE ='
    END AS trend
FROM sales_with_ma
WHERE sale_date >= CURRENT_DATE - INTERVAL '90 days';
```

### Key Concepts
- Moving averages, Statistical analysis, Trend detection, Time-series analytics

---

## Challenge 9: Complex Ranking with Ties 🔴

**Difficulty:** Hard  
**Topic:** Advanced ranking scenarios

### Problem
Create a sales leaderboard with rank, year-over-year comparison.

### Solution
```sql
WITH employee_sales AS (
    SELECT 
        e.employee_id,
        e.first_name || ' ' || e.last_name AS employee_name,
        EXTRACT(YEAR FROM o.order_date) AS year,
        SUM(o.total) AS total_sales
    FROM employees e
    INNER JOIN orders o ON e.employee_id = o.employee_id
    WHERE e.job_title LIKE '%Sales%'
    GROUP BY e.employee_id, e.first_name, e.last_name, EXTRACT(YEAR FROM o.order_date)
),
ranked_sales AS (
    SELECT 
        *,
        DENSE_RANK() OVER (PARTITION BY year ORDER BY total_sales DESC) AS rank,
        PERCENT_RANK() OVER (PARTITION BY year ORDER BY total_sales DESC) AS percentile,
        LAG(total_sales) OVER (PARTITION BY employee_id ORDER BY year) AS prev_year_sales
    FROM employee_sales
)
SELECT 
    year,
    rank,
    employee_name,
    ROUND(total_sales, 2) AS total_sales,
    ROUND(percentile * 100, 1) || '%' AS top_percent,
    CASE 
        WHEN prev_year_sales IS NULL THEN 'NEW'
        ELSE ROUND(((total_sales - prev_year_sales) / prev_year_sales * 100), 1) || '%'
    END AS yoy_growth
FROM ranked_sales
ORDER BY year DESC, rank;
```

### Key Concepts
- Multiple ranking functions, Percentile calculation, Year-over-year analysis

---

## Challenge 10: Query Optimization Challenge 🔥

**Difficulty:** Expert  
**Topic:** Performance optimization

### Problem
Optimize a slow query finding customers who ordered every product in a category.

### Solution
```sql
-- Optimized with CTEs and aggregation
WITH category_products AS (
    SELECT product_id FROM products WHERE category_id = 2
),
product_count AS (
    SELECT COUNT(*) AS total_products FROM category_products
),
customer_products AS (
    SELECT 
        o.customer_id,
        COUNT(DISTINCT oi.product_id) AS products_ordered
    FROM orders o
    INNER JOIN order_items oi ON o.order_id = oi.order_id
    INNER JOIN category_products cp ON oi.product_id = cp.product_id
    GROUP BY o.customer_id
)
SELECT c.customer_name, cp.products_ordered
FROM customers c
INNER JOIN customer_products cp ON c.customer_id = cp.customer_id
CROSS JOIN product_count pc
WHERE cp.products_ordered = pc.total_products;

-- Compare with EXPLAIN ANALYZE
EXPLAIN (ANALYZE, BUFFERS) 
-- Run both queries
```

### Key Concepts
- Query optimization, Eliminating correlated subqueries, Set-based thinking

---

## Challenge 11: Dynamic Pivot Tables 🔥

**Difficulty:** Expert  
**Topic:** Dynamic SQL and pivoting

### Problem
Create a dynamic pivot showing products vs. months with sales quantities.

### Solution
```sql
DO $$
DECLARE
    month_columns TEXT;
    pivot_query TEXT;
BEGIN
    SELECT STRING_AGG(
        DISTINCT 
        'SUM(CASE WHEN month = ''' || TO_CHAR(order_date, 'YYYY-MM') || 
        ''' THEN quantity ELSE 0 END) AS "' || TO_CHAR(order_date, 'YYYY-MM') || '"',
        ', '
    ) INTO month_columns
    FROM orders
    WHERE order_date >= CURRENT_DATE - INTERVAL '6 months';
    
    pivot_query := '
    WITH sales_data AS (
        SELECT 
            p.product_name,
            TO_CHAR(o.order_date, ''YYYY-MM'') AS month,
            SUM(oi.quantity) AS quantity
        FROM products p
        LEFT JOIN order_items oi ON p.product_id = oi.product_id
        LEFT JOIN orders o ON oi.order_id = o.order_id
        GROUP BY p.product_name, month
    )
    SELECT product_name, ' || month_columns || '
    FROM sales_data
    GROUP BY product_name;
    ';
    
    EXECUTE pivot_query;
END $$;
```

### Key Concepts
- Dynamic SQL, String aggregation, EXECUTE statement, PL/pgSQL

---

## Challenge 12: Complete ETL Pipeline 🔥

**Difficulty:** Expert  
**Topic:** Real-world data pipeline

### Problem
Create a complete ETL process with extraction, transformation, loading, and error handling.

### Solution
```sql
CREATE OR REPLACE FUNCTION process_order_staging()
RETURNS TABLE(status TEXT, processed INT, errors INT) AS $$
DECLARE
    v_processed INT := 0;
    v_errors INT := 0;
BEGIN
    -- Log batch start
    INSERT INTO batch_log (process_name, execution_time)
    VALUES ('process_orders', NOW());
    
    BEGIN
        -- Extract & Transform: Validate data
        WITH validated_orders AS (
            SELECT 
                *,
                CASE 
                    WHEN customer_id IS NULL THEN 'Missing customer'
                    WHEN total < 0 THEN 'Invalid total'
                    ELSE 'OK'
                END AS validation_status
            FROM staging_orders
            WHERE processed = FALSE
        )
        -- Load: Insert valid orders
        INSERT INTO orders (customer_id, order_date, total)
        SELECT customer_id, order_date, total
        FROM validated_orders
        WHERE validation_status = 'OK';
        
        GET DIAGNOSTICS v_processed = ROW_COUNT;
        
        -- Log errors
        INSERT INTO billing_errors (customer_id, error_message)
        SELECT customer_id, validation_status
        FROM validated_orders
        WHERE validation_status != 'OK';
        
        SELECT COUNT(*) INTO v_errors 
        FROM validated_orders WHERE validation_status != 'OK';
        
    EXCEPTION
        WHEN OTHERS THEN
            v_errors := v_errors + 1;
    END;
    
    RETURN QUERY SELECT 'SUCCESS'::TEXT, v_processed, v_errors;
END;
$$ LANGUAGE plpgsql;
```

### Key Concepts
- ETL pipeline design, Error handling, Transaction management, Logging and auditing

---

## 📚 Summary - Part 6: Industry Advanced

### What You've Learned

✅ **Recursive Queries:** Bill of materials, Graph traversal, Hierarchical data  
✅ **Advanced Analytics:** Cohort analysis, RFM segmentation, Time-series, Moving averages  
✅ **Data Quality:** Gap/island detection, Duplicate detection, Fuzzy matching  
✅ **Query Optimization:** Eliminating correlated subqueries, Set-based thinking, EXPLAIN ANALYZE  
✅ **Production Patterns:** ETL pipelines, Dynamic SQL, Error handling, Audit logging

### Real-World Applications

- **E-commerce**: Product recommendations, inventory management  
- **SaaS**: Cohort retention, churn prediction  
- **Finance**: Fraud detection, risk analysis  
- **Manufacturing**: Supply chain optimization  
- **Telecommunications**: Network optimization

### Key Takeaways

1. Recursive CTEs are powerful but use carefully
2. Set-based operations beat row-by-row processing
3. Window functions solve complex analytical problems elegantly
4. Always validate and log in production systems
5. EXPLAIN ANALYZE before optimizing
6. Think in sets, not loops

---

## 🎓 Congratulations!

You've completed all 6 parts of the SQL Practice Guide!

### Your Journey
- **Part 1**: Fundamentals (15 challenges)  
- **Part 2**: Intermediate Queries (15 challenges)  
- **Part 3**: Advanced Queries (15 challenges)  
- **Part 4**: Data Manipulation (12 challenges)  
- **Part 5**: Database Design (10 challenges)  
- **Part 6**: Industry Advanced (12 challenges)

**Total: 79 comprehensive SQL challenges based on `sql-practice-database.sql`!**

### What Next?

1. **Practice regularly** - SQL improves with use  
2. **Real projects** - Apply to actual business problems  
3. **Specialize** - Deep dive into analytics, optimization, or architecture  
4. **Stay updated** - New PostgreSQL features released regularly

**Back to:** [Main Index](file:///c:/Users/phusukale/Downloads/Docs/Repo/SQL_Challanges/sql-challenges-index.md)

**Keep querying, keep learning, keep building! 🚀**
