# SQL Challenges - Part 3: Advanced Queries

**Difficulty Range:** 🟡 Medium to 🔴 Hard  
**Total Challenges:** 15  
**Topics Covered:** Window Functions, CTEs, Complex JOINs, Correlated Subqueries, Advanced Analytics

**Database:** All challenges use `sql-practice-database.sql` (company_db)

---

## Challenge 1: ROW_NUMBER - Basic Ranking 🟡

**Difficulty:** Medium  
**Topic:** Window functions introduction

### Problem
Assign a sequential number to each employee ordered by salary (highest first).

### Solution
```sql
SELECT 
    ROW_NUMBER() OVER (ORDER BY salary DESC) AS row_num,
    first_name || ' ' || last_name AS employee_name,
    salary
FROM employees
WHERE status = 'ACTIVE'
ORDER BY row_num;
```

### Explanation
- `ROW_NUMBER()` assigns unique sequential numbers
- `OVER (ORDER BY salary DESC)` defines the ordering
- Numbers are always unique (1, 2, 3, ...)
- Window functions don't reduce rows (unlike GROUP BY)

### Key Concepts
- Window function syntax, OVER clause, ROW_NUMBER vs RANK

---

## Challenge 2: RANK Within Partitions 🟡

**Difficulty:** Medium  
**Topic:** PARTITION BY clause

### Problem
Rank employees by salary within each department.

### Solution
```sql
SELECT 
    d.department_name,
    e.first_name || ' ' || e.last_name AS employee_name,
    e.salary,
    RANK() OVER (PARTITION BY d.department_id ORDER BY e.salary DESC) AS dept_rank
FROM employees e
INNER JOIN departments d ON e.department_id = d.department_id
WHERE e.status = 'ACTIVE'
ORDER BY d.department_name, dept_rank;
```

### Explanation
- `PARTITION BY` creates separate rankings per department
- Each partition has its own ranking (1, 2, 3...)
- Like GROUP BY but doesn't collapse rows

### Key Concepts
- PARTITION BY clause, Per-group rankings

---

## Challenge 3: Running Total 🔴

**Difficulty:** Hard  
**Topic:** Running aggregates with window functions

### Problem
Calculate the running total of order amounts by customer, ordered by date.

### Solution
```sql
SELECT 
    c.customer_name,
    o.order_date,
    o.total AS order_total,
    SUM(o.total) OVER (
        PARTITION BY c.customer_id 
        ORDER BY o.order_date
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS running_total
FROM orders o
INNER JOIN customers c ON o.customer_id = c.customer_id
ORDER BY c.customer_name, o.order_date;
```

### Explanation
- `SUM() OVER` creates running total
- `PARTITION BY customer_id` resets for each customer
- `ROWS BETWEEN` defines window frame
- Essential for cumulative analytics

### Key Concepts
- Running totals, Window frame specification, ROWS vs RANGE

---

## Challenge 4: LAG and LEAD Functions 🔴

**Difficulty:** Hard  
**Topic:** Accessing adjacent rows

### Problem
For each order, show the previous order total and next order total for the same customer.

### Solution
```sql
SELECT 
    c.customer_name,
    o.order_date,
    o.total AS current_total,
    LAG(o.total) OVER (PARTITION BY c.customer_id ORDER BY o.order_date) AS previous_total,
    LEAD(o.total) OVER (PARTITION BY c.customer_id ORDER BY o.order_date) AS next_total
FROM orders o
INNER JOIN customers c ON o.customer_id = c.customer_id
ORDER BY c.customer_name, o.order_date;
```

### Explanation
- `LAG(column)` accesses previous row's value
- `LEAD(column)` accesses next row's value
- Returns NULL when no previous/next row exists
- Useful for period-over-period comparisons

### Key Concepts
- LAG/LEAD functions, Row-to-row comparisons

---

## Challenge 5: Common Table Expression (CTE) - Basic 🟡

**Difficulty:** Medium  
**Topic:** Introduction to CTEs

### Problem
Use a CTE to find employees earning above their department's average salary.

### Solution
```sql
WITH dept_avg AS (
    SELECT 
        department_id,
        AVG(salary) AS avg_salary
    FROM employees
    WHERE status = 'ACTIVE'
    GROUP BY department_id
)
SELECT 
    e.first_name || ' ' || e.last_name AS employee_name,
    d.department_name,
    e.salary,
    ROUND(da.avg_salary, 2) AS dept_avg_salary
FROM employees e
INNER JOIN departments d ON e.department_id = d.department_id
INNER JOIN dept_avg da ON e.department_id = da.department_id
WHERE e.salary > da.avg_salary
ORDER BY d.department_name, e.salary DESC;
```

### Explanation
- `WITH` clause defines a named temporary result set
- CTE makes complex queries more readable
- Can be referenced multiple times in main query
- Executed once and results reused

### Key Concepts
- CTE syntax (WITH ... AS), Query readability, Breaking complex queries into steps

---

## Challenge 6: Recursive CTE 🔥

**Difficulty:** Expert  
**Topic:** Recursive queries

### Problem
Build an employee hierarchy showing the full management chain from CEO to all employees.

### Solution
```sql
WITH RECURSIVE employee_hierarchy AS (
    -- Base case: top-level employees (no manager)
    SELECT 
        employee_id,
        first_name || ' ' || last_name AS employee_name,
        manager_id,
        NULL::TEXT AS manager_name,
        1 AS level,
        first_name || ' ' || last_name AS hierarchy_path
    FROM employees
    WHERE manager_id IS NULL AND status = 'ACTIVE'
    
    UNION ALL
    
    -- Recursive case: employees with managers
    SELECT 
        e.employee_id,
        e.first_name || ' ' || e.last_name,
        e.manager_id,
        eh.employee_name,
        eh.level + 1,
        eh.hierarchy_path || ' -> ' || e.first_name || ' ' || e.last_name
    FROM employees e
    INNER JOIN employee_hierarchy eh ON e.manager_id = eh.employee_id
    WHERE e.status = 'ACTIVE'
)
SELECT 
    level,
    employee_name,
    manager_name,
    hierarchy_path
FROM employee_hierarchy
ORDER BY hierarchy_path;
```

### Explanation
- `WITH RECURSIVE` enables recursive queries
- Base case: starting point (CEO with no manager)
- Recursive case: builds on previous results
- Automatically terminates when no new rows
- Critical for hierarchical data traversal

### Key Concepts
- Recursive CTEs, Hierarchical data traversal, Base case + recursive case pattern

---

## Challenge 7: Moving Average 🔴

**Difficulty:** Hard  
**Topic:** Window frames with ROWS

### Problem
Calculate a 3-order moving average of order totals for each customer.

### Solution
```sql
SELECT 
    c.customer_name,
    o.order_date,
    o.total,
    ROUND(AVG(o.total) OVER (
        PARTITION BY c.customer_id 
        ORDER BY o.order_date
        ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
    ), 2) AS moving_avg_3
FROM orders o
INNER JOIN customers c ON o.customer_id = c.customer_id
ORDER BY c.customer_name, o.order_date;
```

### Explanation
- `ROWS BETWEEN 2 PRECEDING AND CURRENT ROW` = window of 3 rows
- Moving average smooths out variations
- Common in time-series analysis
- Window adjusts as you move through data

### Key Concepts
- Moving averages, Window frame boundaries, ROWS BETWEEN syntax

---

## Challenge 8: NTILE - Quartiles 🟡

**Difficulty:** Medium  
**Topic:** NTILE function

### Problem
Divide employees into 4 salary quartiles.

### Solution
```sql
SELECT 
    first_name || ' ' || last_name AS employee_name,
    salary,
    NTILE(4) OVER (ORDER BY salary DESC) AS salary_quartile
FROM employees
WHERE status = 'ACTIVE'
ORDER BY salary DESC;
```

### Explanation
- `NTILE(n)` divides rows into n roughly equal groups
- Quartile 1 = top 25%, Quartile 4 = bottom 25%
- Useful for percentile analysis
- If rows don't divide evenly, first groups get extra rows

### Key Concepts
- NTILE function, Percentile/quartile analysis, Group distribution

---

## Challenge 9: FIRST_VALUE and LAST_VALUE 🔴

**Difficulty:** Hard  
**Topic:** FIRST_VALUE and LAST_VALUE functions

### Problem
For each order, show how it compares to the customer's first and most recent orders.

### Solution
```sql
SELECT 
    c.customer_name,
    o.order_date,
    o.total,
    FIRST_VALUE(o.total) OVER (
        PARTITION BY c.customer_id 
        ORDER BY o.order_date
        ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
    ) AS first_order_total,
    LAST_VALUE(o.total) OVER (
        PARTITION BY c.customer_id 
        ORDER BY o.order_date
        ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
    ) AS latest_order_total
FROM orders o
INNER JOIN customers c ON o.customer_id = c.customer_id
ORDER BY c.customer_name, o.order_date;
```

### Explanation
- `FIRST_VALUE` retrieves first value in window
- `LAST_VALUE` retrieves last value in window
- `UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING` ensures full partition
- Without proper frame, LAST_VALUE gives unexpected results

### Key Concepts
- FIRST_VALUE/LAST_VALUE, Importance of window frame, Accessing boundary values

---

## Challenge 10: Correlated Subquery 🔴

**Difficulty:** Hard  
**Topic:** Correlated subqueries

### Problem
Find products whose price is above average for their category.

### Solution
```sql
SELECT 
    p.product_name,
    p.category_id,
    p.price,
    (SELECT ROUND(AVG(price), 2) 
     FROM products p2 
     WHERE p2.category_id = p.category_id) AS category_avg_price
FROM products p
WHERE p.price > (
    SELECT AVG(price) 
    FROM products p2 
    WHERE p2.category_id = p.category_id
)
ORDER BY p.category_id, p.price DESC;
```

### Explanation
- Subquery references outer query (correlated)
- Executes once for each row in outer query
- `p.category_id` from outer query used in inner query
- Can be slow on large datasets

### Key Concepts
- Correlated subqueries, Row-by-row execution, Subquery referencing outer query

### Better Performance Alternative
```sql
WITH product_stats AS (
    SELECT 
        product_id,
        product_name,
        category_id,
        price,
        AVG(price) OVER (PARTITION BY category_id) AS category_avg_price
    FROM products
)
SELECT *
FROM product_stats
WHERE price > category_avg_price
ORDER BY category_id, price DESC;
```

---

## Challenge 11: Complex CTE Chain 🔴

**Difficulty:** Hard  
**Topic:** Multiple CTEs working together

### Problem
Create a sales performance report showing monthly order counts, revenue, year-to-date running totals, and month-over-month growth.

### Solution
```sql
WITH monthly_stats AS (
    SELECT 
        DATE_TRUNC('month', order_date) AS month,
        COUNT(*) AS orders,
        SUM(total) AS revenue
    FROM orders
    WHERE EXTRACT(YEAR FROM order_date) = 2024
    GROUP BY DATE_TRUNC('month', order_date)
),
with_ytd AS (
    SELECT 
        month,
        orders,
        revenue,
        SUM(revenue) OVER (ORDER BY month) AS ytd_revenue
    FROM monthly_stats
),
with_growth AS (
    SELECT 
        month,
        orders,
        ROUND(revenue, 2) AS revenue,
        ROUND(ytd_revenue, 2) AS ytd_revenue,
        ROUND(
            ((revenue - LAG(revenue) OVER (ORDER BY month)) / 
             NULLIF(LAG(revenue) OVER (ORDER BY month), 0)) * 100,
            2
        ) AS mom_growth_pct
    FROM with_ytd
)
SELECT * FROM with_growth
ORDER BY month;
```

### Explanation
- Multiple CTEs build on each other
- Each CTE adds new calculations
- More readable than nested subqueries
- Intermediate results clearly defined

### Key Concepts
- CTE chaining, Building complex calculations step-by-step, Query organization

---

## Challenge 12: Self-Join for Data Comparison 🟡

**Difficulty:** Medium  
**Topic:** Self-joins with conditions

### Problem
Find all pairs of employees in the same department with the same salary.

### Solution
```sql
SELECT 
    d.department_name,
    e1.first_name || ' ' || e1.last_name AS employee1,
    e2.first_name || ' ' || e2.last_name AS employee2,
    e1.salary
FROM employees e1
INNER JOIN employees e2 ON e1.department_id = e2.department_id 
    AND e1.salary = e2.salary
    AND e1.employee_id < e2.employee_id
INNER JOIN departments d ON e1.department_id = d.department_id
WHERE e1.status = 'ACTIVE' AND e2.status = 'ACTIVE'
ORDER BY d.department_name, e1.salary DESC;
```

### Explanation
- Table joined to itself for comparison
- `e1.employee_id < e2.employee_id` prevents duplicate pairs
- Finds matching records within same table

### Key Concepts
- Self-join techniques, Avoiding duplicate pairs, Comparison queries

---

## Challenge 13: Pivot with CASE 🔴

**Difficulty:** Hard  
**Topic:** Creating pivot tables

### Problem
Create a pivot table showing order counts by status across different customer tiers.

### Solution
```sql
SELECT 
    c.tier,
    COUNT(CASE WHEN o.status = 'pending' THEN 1 END) AS pending,
    COUNT(CASE WHEN o.status = 'processing' THEN 1 END) AS processing,
    COUNT(CASE WHEN o.status = 'shipped' THEN 1 END) AS shipped,
    COUNT(CASE WHEN o.status = 'delivered' THEN 1 END) AS delivered,
    COUNT(o.order_id) AS total_orders
FROM customers c
LEFT JOIN orders o ON c.customer_id = o.customer_id
GROUP BY c.tier
ORDER BY 
    CASE c.tier 
        WHEN 'GOLD' THEN 1 
        WHEN 'SILVER' THEN 2 
        WHEN 'BRONZE' THEN 3 
    END;
```

### Explanation
- CASE statement creates columns from rows
- COUNT with CASE performs conditional aggregation
- Transforms vertical data to horizontal format
- Powerful reporting technique

### Key Concepts
- Pivot table creation, Conditional aggregation, CASE with aggregate functions

---

## Challenge 14: Dense Ranking with Ties 🟡

**Difficulty:** Medium  
**Topic:** Handling ties in rankings

### Problem
Create a leaderboard of sales representatives by total sales, handling ties properly.

### Solution
```sql
WITH sales_performance AS (
    SELECT 
        e.employee_id,
        e.first_name || ' ' || e.last_name AS sales_rep,
        COUNT(DISTINCT o.customer_id) AS customers_served,
        COALESCE(SUM(o.total), 0) AS total_sales
    FROM employees e
    LEFT JOIN orders o ON e.employee_id = o.employee_id
    WHERE e.job_title LIKE '%Sales%' AND e.status = 'ACTIVE'
    GROUP BY e.employee_id, e.first_name, e.last_name
)
SELECT 
    DENSE_RANK() OVER (ORDER BY total_sales DESC) AS rank,
    sales_rep,
    ROUND(total_sales, 2) AS total_sales,
    customers_served
FROM sales_performance
ORDER BY rank, sales_rep;
```

### Explanation
- DENSE_RANK handles ties without gaps
- Multiple employees with same sales get same rank
- Next rank continues without gaps (1, 2, 2, 3 not 1, 2, 2, 4)

### Key Concepts
- DENSE_RANK vs RANK, Tie handling in rankings, Leaderboard queries

---

## Challenge 15: Advanced Analytical Query 🔥

**Difficulty:** Expert  
**Topic:** Combining multiple advanced techniques

### Problem
Create a comprehensive customer analysis showing tier, total orders and revenue, rank within tier, percentage of tier's total revenue, and running total within tier.

### Solution
```sql
WITH customer_stats AS (
    SELECT 
        c.customer_id,
        c.customer_name,
        c.tier,
        COUNT(o.order_id) AS orders,
        COALESCE(SUM(o.total), 0) AS revenue
    FROM customers c
    LEFT JOIN orders o ON c.customer_id = o.customer_id
    WHERE c.status = 'ACTIVE'
    GROUP BY c.customer_id, c.customer_name, c.tier
),
tier_totals AS (
    SELECT 
        tier,
        SUM(revenue) AS tier_revenue
    FROM customer_stats
    GROUP BY tier
),
enriched_stats AS (
    SELECT 
        cs.*,
        tt.tier_revenue,
        RANK() OVER (PARTITION BY cs.tier ORDER BY cs.revenue DESC) AS tier_rank,
        SUM(cs.revenue) OVER (
            PARTITION BY cs.tier 
            ORDER BY cs.revenue DESC
            ROWS UNBOUNDED PRECEDING
        ) AS running_total
    FROM customer_stats cs
    INNER JOIN tier_totals tt ON cs.tier = tt.tier
)
SELECT 
    tier,
    customer_name,
    orders,
    ROUND(revenue, 2) AS revenue,
    tier_rank,
    ROUND((revenue / tier_revenue * 100), 1) || '%' AS pct_of_tier,
    ROUND(running_total, 2) AS running_total
FROM enriched_stats
ORDER BY 
    CASE tier WHEN 'GOLD' THEN 1 WHEN 'SILVER' THEN 2 WHEN 'BRONZE' THEN 3 END,
    tier_rank;
```

### Explanation
- Multiple CTEs build analysis layer by layer
- Window functions for ranking and running totals
- PARTITION BY for tier-specific calculations
- Percentage calculations using tier totals
- Real-world analytical query structure

### Key Concepts
- Multi-level analytical queries, Combining CTEs and window functions, Business intelligence reporting

---

## 📚 Summary - Part 3: Advanced Queries

### What You've Learned

✅ **Window Functions:** ROW_NUMBER, RANK, DENSE_RANK, LAG/LEAD, FIRST_VALUE/LAST_VALUE, NTILE  
✅ **Common Table Expressions:** Basic CTEs, Multiple CTE chaining, Recursive CTEs  
✅ **Running Calculations:** Running totals, Moving averages, Cumulative aggregations  
✅ **Advanced Analysis:** Correlated subqueries, Self-joins, Pivot tables, Complex multi-step queries

### Key Takeaways

1. Window functions don't reduce rows - Unlike GROUP BY
2. PARTITION BY is like GROUP BY for window functions
3. Window frames matter - Especially for LAST_VALUE
4. CTEs improve readability - Break complex logic into steps
5. Recursive CTEs are powerful for hierarchical data
6. LAG/LEAD simplify period-over-period comparisons

### Performance Tips

- CTE vs Subquery: CTEs often more readable, similar performance
- Window Functions: Usually better than correlated subqueries
- Recursive CTEs: Can be expensive, use carefully
- Indexes: Window functions benefit from indexes on PARTITION BY and ORDER BY columns

**Continue to:** [Part 4: Data Manipulation](file:///c:/Users/phusukale/Downloads/Docs/Repo/SQL_Challanges/sql-challenges-part4-data-manipulation.md)

**🎯 Bonus Challenges:** Find month with highest sales growth, Calculate employee tenure, Identify gaps in sequences, Analyze declining sales trends, Create customer segmentation using RFM

**Master these concepts! 🚀**
