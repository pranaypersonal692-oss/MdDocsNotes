# Comprehensive Guide to Writing Complex and Performant SQL Queries

> [!NOTE]
> This guide covers SQL from fundamental concepts to advanced optimization techniques for building scalable, production-ready database solutions.

---

## Table of Contents

1. [SQL Fundamentals](#sql-fundamentals)
2. [Intermediate SQL Concepts](#intermediate-sql-concepts)
3. [Advanced Query Techniques](#advanced-query-techniques)
4. [Performance Optimization](#performance-optimization)
5. [Scalability Best Practices](#scalability-best-practices)
6. [Query Analysis and Troubleshooting](#query-analysis-and-troubleshooting)
7. [Real-World Patterns and Anti-Patterns](#real-world-patterns-and-anti-patterns)

---

## SQL Fundamentals

### 1.1 Basic SELECT Statements

The `SELECT` statement is the foundation of SQL queries. It retrieves data from one or more tables.

**Basic Syntax:**
```sql
SELECT column1, column2, column3
FROM table_name;
```

**Select All Columns:**
```sql
SELECT * FROM employees;
```

> [!TIP]
> Avoid using `SELECT *` in production code. Always specify the columns you need to reduce network overhead and improve query clarity.

**Select Distinct Values:**
```sql
SELECT DISTINCT department_id 
FROM employees;
```

**Explanation:** `DISTINCT` eliminates duplicate rows from the result set. This operation requires sorting or hashing, which can be expensive on large datasets.

### 1.2 WHERE Clause - Filtering Data

The `WHERE` clause filters rows based on specified conditions.

```sql
SELECT first_name, last_name, salary
FROM employees
WHERE salary > 50000;
```

**Multiple Conditions:**
```sql
SELECT first_name, last_name, department_id
FROM employees
WHERE salary > 50000 
  AND department_id = 10
  OR department_id = 20;
```

> [!IMPORTANT]
> Use parentheses to make complex logic explicit: `WHERE (condition1 AND condition2) OR condition3`

**Common Operators:**
- `=`, `!=`, `<>` (not equal)
- `<`, `>`, `<=`, `>=`
- `BETWEEN ... AND ...`
- `IN (value1, value2, ...)`
- `LIKE` (pattern matching)
- `IS NULL`, `IS NOT NULL`

**Examples:**
```sql
-- BETWEEN
SELECT * FROM orders 
WHERE order_date BETWEEN '2024-01-01' AND '2024-12-31';

-- IN
SELECT * FROM products 
WHERE category_id IN (1, 3, 5, 7);

-- LIKE (% matches any sequence of characters)
SELECT * FROM customers 
WHERE email LIKE '%@gmail.com';

-- NULL handling
SELECT * FROM employees 
WHERE manager_id IS NULL;
```

### 1.3 ORDER BY - Sorting Results

```sql
SELECT first_name, last_name, salary
FROM employees
ORDER BY salary DESC;
```

**Multiple Column Sorting:**
```sql
SELECT first_name, last_name, department_id, salary
FROM employees
ORDER BY department_id ASC, salary DESC;
```

**Explanation:** Rows are first sorted by `department_id` in ascending order, then within each department, by `salary` in descending order.

### 1.4 LIMIT and OFFSET - Pagination

```sql
-- Get first 10 rows
SELECT * FROM products
ORDER BY product_id
LIMIT 10;

-- Get rows 11-20 (pagination)
SELECT * FROM products
ORDER BY product_id
LIMIT 10 OFFSET 10;
```

> [!WARNING]
> Large `OFFSET` values are inefficient. The database still processes all skipped rows. Use cursor-based pagination for better performance.

### 1.5 Aggregate Functions

Aggregate functions perform calculations on a set of values and return a single value.

```sql
SELECT 
    COUNT(*) as total_employees,
    COUNT(DISTINCT department_id) as total_departments,
    AVG(salary) as average_salary,
    MIN(salary) as min_salary,
    MAX(salary) as max_salary,
    SUM(salary) as total_payroll
FROM employees;
```

**Common Aggregate Functions:**
- `COUNT()` - Count rows
- `SUM()` - Sum values
- `AVG()` - Average value
- `MIN()` - Minimum value
- `MAX()` - Maximum value

### 1.6 GROUP BY - Aggregating by Categories

```sql
SELECT 
    department_id,
    COUNT(*) as employee_count,
    AVG(salary) as avg_salary
FROM employees
GROUP BY department_id;
```

**Explanation:** `GROUP BY` divides rows into groups based on specified columns, then applies aggregate functions to each group.

### 1.7 HAVING - Filtering Aggregated Results

```sql
SELECT 
    department_id,
    COUNT(*) as employee_count,
    AVG(salary) as avg_salary
FROM employees
GROUP BY department_id
HAVING COUNT(*) > 5;
```

> [!IMPORTANT]
> `WHERE` filters rows before grouping; `HAVING` filters groups after aggregation.

**Order of Execution:**
1. `FROM` - Identify tables
2. `WHERE` - Filter rows
3. `GROUP BY` - Group rows
4. `HAVING` - Filter groups
5. `SELECT` - Select columns
6. `ORDER BY` - Sort results
7. `LIMIT` - Limit rows

---

## Intermediate SQL Concepts

### 2.1 JOINs - Combining Data from Multiple Tables

JOINs are fundamental to relational databases and allow you to combine data from multiple tables.

#### INNER JOIN

Returns only rows where there's a match in both tables.

```sql
SELECT 
    e.first_name,
    e.last_name,
    d.department_name
FROM employees e
INNER JOIN departments d ON e.department_id = d.department_id;
```

**Explanation:** Only employees who belong to a department (and departments that have employees) appear in the result.

#### LEFT JOIN (LEFT OUTER JOIN)

Returns all rows from the left table and matching rows from the right table. If no match, NULL values appear for right table columns.

```sql
SELECT 
    e.first_name,
    e.last_name,
    d.department_name
FROM employees e
LEFT JOIN departments d ON e.department_id = d.department_id;
```

**Use Case:** Find all employees, including those not assigned to any department.

#### RIGHT JOIN (RIGHT OUTER JOIN)

Returns all rows from the right table and matching rows from the left table.

```sql
SELECT 
    e.first_name,
    e.last_name,
    d.department_name
FROM employees e
RIGHT JOIN departments d ON e.department_id = d.department_id;
```

**Use Case:** Find all departments, including those with no employees.

#### FULL OUTER JOIN

Returns all rows from both tables, with NULLs where there's no match.

```sql
SELECT 
    e.first_name,
    e.last_name,
    d.department_name
FROM employees e
FULL OUTER JOIN departments d ON e.department_id = d.department_id;
```

#### CROSS JOIN

Returns the Cartesian product of both tables (all possible combinations).

```sql
SELECT 
    p.product_name,
    s.size_name
FROM products p
CROSS JOIN sizes s;
```

**Use Case:** Generate all possible product-size combinations.

#### SELF JOIN

A table joined with itself.

```sql
SELECT 
    e.first_name as employee,
    m.first_name as manager
FROM employees e
LEFT JOIN employees m ON e.manager_id = m.employee_id;
```

**Explanation:** Finds each employee's manager by joining the employees table to itself.

#### Multiple JOINs

```sql
SELECT 
    e.first_name,
    e.last_name,
    d.department_name,
    l.city,
    l.country
FROM employees e
INNER JOIN departments d ON e.department_id = d.department_id
INNER JOIN locations l ON d.location_id = l.location_id;
```

### 2.2 Subqueries

A subquery is a query nested inside another query.

#### Subquery in WHERE Clause

```sql
SELECT first_name, last_name, salary
FROM employees
WHERE salary > (
    SELECT AVG(salary) 
    FROM employees
);
```

**Explanation:** Finds employees earning more than the average salary.

#### Subquery in SELECT Clause

```sql
SELECT 
    first_name,
    last_name,
    salary,
    (SELECT AVG(salary) FROM employees) as avg_company_salary,
    salary - (SELECT AVG(salary) FROM employees) as salary_diff
FROM employees;
```

#### Subquery in FROM Clause (Derived Tables)

```sql
SELECT 
    dept_avg.department_id,
    dept_avg.avg_salary
FROM (
    SELECT 
        department_id,
        AVG(salary) as avg_salary
    FROM employees
    GROUP BY department_id
) dept_avg
WHERE dept_avg.avg_salary > 60000;
```

#### Correlated Subqueries

A correlated subquery references columns from the outer query.

```sql
SELECT 
    e1.first_name,
    e1.last_name,
    e1.department_id,
    e1.salary
FROM employees e1
WHERE salary > (
    SELECT AVG(e2.salary)
    FROM employees e2
    WHERE e2.department_id = e1.department_id
);
```

**Explanation:** Finds employees earning more than their department's average salary. The subquery is executed once for each row in the outer query.

> [!WARNING]
> Correlated subqueries can be slow on large datasets. Consider using JOINs or window functions instead.

#### EXISTS and NOT EXISTS

```sql
-- Find departments with at least one employee
SELECT department_name
FROM departments d
WHERE EXISTS (
    SELECT 1 
    FROM employees e 
    WHERE e.department_id = d.department_id
);

-- Find departments with no employees
SELECT department_name
FROM departments d
WHERE NOT EXISTS (
    SELECT 1 
    FROM employees e 
    WHERE e.department_id = d.department_id
);
```

**Explanation:** `EXISTS` returns true if the subquery returns any rows. It's often more efficient than `IN` for large datasets.

### 2.3 Common Table Expressions (CTEs)

CTEs improve query readability by allowing you to define temporary named result sets.

#### Basic CTE

```sql
WITH department_stats AS (
    SELECT 
        department_id,
        COUNT(*) as employee_count,
        AVG(salary) as avg_salary
    FROM employees
    GROUP BY department_id
)
SELECT 
    d.department_name,
    ds.employee_count,
    ds.avg_salary
FROM departments d
INNER JOIN department_stats ds ON d.department_id = ds.department_id
WHERE ds.avg_salary > 60000;
```

#### Multiple CTEs

```sql
WITH 
high_earners AS (
    SELECT employee_id, first_name, last_name, salary
    FROM employees
    WHERE salary > 80000
),
dept_counts AS (
    SELECT department_id, COUNT(*) as total_employees
    FROM employees
    GROUP BY department_id
)
SELECT 
    he.first_name,
    he.last_name,
    he.salary,
    dc.total_employees
FROM high_earners he
INNER JOIN employees e ON he.employee_id = e.employee_id
INNER JOIN dept_counts dc ON e.department_id = dc.department_id;
```

> [!TIP]
> CTEs improve maintainability and readability, especially for complex queries. They're also useful for recursive queries.

### 2.4 UNION, INTERSECT, and EXCEPT

#### UNION

Combines results from multiple SELECT statements, removing duplicates.

```sql
SELECT first_name, last_name FROM employees
WHERE department_id = 10
UNION
SELECT first_name, last_name FROM employees
WHERE salary > 80000;
```

**UNION ALL** - Includes duplicates (faster):

```sql
SELECT first_name, last_name FROM employees
WHERE department_id = 10
UNION ALL
SELECT first_name, last_name FROM employees
WHERE salary > 80000;
```

> [!TIP]
> Use `UNION ALL` when you know there are no duplicates or when duplicates are acceptable. It's faster than `UNION` because it skips the deduplication step.

#### INTERSECT

Returns only rows that appear in both result sets.

```sql
SELECT employee_id FROM project_team_a
INTERSECT
SELECT employee_id FROM project_team_b;
```

#### EXCEPT (or MINUS)

Returns rows from the first query that don't appear in the second.

```sql
SELECT employee_id FROM all_employees
EXCEPT
SELECT employee_id FROM terminated_employees;
```

### 2.5 CASE Statements

The `CASE` expression adds conditional logic to queries.

#### Simple CASE

```sql
SELECT 
    first_name,
    last_name,
    salary,
    CASE 
        WHEN salary < 40000 THEN 'Low'
        WHEN salary BETWEEN 40000 AND 80000 THEN 'Medium'
        WHEN salary > 80000 THEN 'High'
        ELSE 'Unknown'
    END as salary_category
FROM employees;
```

#### Using CASE in Aggregations

```sql
SELECT 
    department_id,
    COUNT(*) as total_employees,
    SUM(CASE WHEN salary > 60000 THEN 1 ELSE 0 END) as high_earners,
    SUM(CASE WHEN salary <= 60000 THEN 1 ELSE 0 END) as regular_earners
FROM employees
GROUP BY department_id;
```

### 2.6 String Functions

```sql
SELECT 
    CONCAT(first_name, ' ', last_name) as full_name,
    UPPER(last_name) as last_name_upper,
    LOWER(email) as email_lower,
    LENGTH(first_name) as name_length,
    SUBSTRING(email, 1, 5) as email_prefix,
    TRIM(phone_number) as cleaned_phone
FROM employees;
```

### 2.7 Date and Time Functions

```sql
SELECT 
    order_date,
    CURRENT_DATE as today,
    CURRENT_TIMESTAMP as now,
    DATE_PART('year', order_date) as order_year,
    DATE_PART('month', order_date) as order_month,
    AGE(CURRENT_DATE, order_date) as order_age,
    order_date + INTERVAL '30 days' as due_date
FROM orders;
```

**Date Arithmetic:**
```sql
-- Orders from last 30 days
SELECT * FROM orders
WHERE order_date >= CURRENT_DATE - INTERVAL '30 days';

-- Orders grouped by month
SELECT 
    DATE_TRUNC('month', order_date) as order_month,
    COUNT(*) as order_count
FROM orders
GROUP BY DATE_TRUNC('month', order_date)
ORDER BY order_month;
```

---

## Advanced Query Techniques

### 3.1 Window Functions

Window functions perform calculations across a set of rows related to the current row, without collapsing the result set like `GROUP BY` does.

#### ROW_NUMBER()

Assigns a unique sequential number to each row within a partition.

```sql
SELECT 
    employee_id,
    first_name,
    last_name,
    department_id,
    salary,
    ROW_NUMBER() OVER (PARTITION BY department_id ORDER BY salary DESC) as salary_rank
FROM employees;
```

**Explanation:** Within each department, employees are ranked by salary. Each employee gets a unique rank.

**Use Case: Get Top N per Group**
```sql
WITH ranked_employees AS (
    SELECT 
        employee_id,
        first_name,
        last_name,
        department_id,
        salary,
        ROW_NUMBER() OVER (PARTITION BY department_id ORDER BY salary DESC) as rank
    FROM employees
)
SELECT * FROM ranked_employees
WHERE rank <= 3;
```

#### RANK() and DENSE_RANK()

```sql
SELECT 
    employee_id,
    first_name,
    salary,
    RANK() OVER (ORDER BY salary DESC) as rank,
    DENSE_RANK() OVER (ORDER BY salary DESC) as dense_rank,
    ROW_NUMBER() OVER (ORDER BY salary DESC) as row_num
FROM employees;
```

**Differences:**
- `ROW_NUMBER()`: Always unique (1, 2, 3, 4, 5, ...)
- `RANK()`: Ties get same rank, next rank skips (1, 2, 2, 4, 5, ...)
- `DENSE_RANK()`: Ties get same rank, no gaps (1, 2, 2, 3, 4, ...)

#### LAG() and LEAD()

Access data from previous or subsequent rows.

```sql
SELECT 
    order_date,
    order_total,
    LAG(order_total, 1) OVER (ORDER BY order_date) as previous_order_total,
    LEAD(order_total, 1) OVER (ORDER BY order_date) as next_order_total,
    order_total - LAG(order_total, 1) OVER (ORDER BY order_date) as difference_from_previous
FROM orders;
```

**Use Case: Compare with Previous Period**
```sql
SELECT 
    DATE_TRUNC('month', order_date) as month,
    SUM(order_total) as monthly_revenue,
    LAG(SUM(order_total), 1) OVER (ORDER BY DATE_TRUNC('month', order_date)) as prev_month_revenue,
    (SUM(order_total) - LAG(SUM(order_total), 1) OVER (ORDER BY DATE_TRUNC('month', order_date))) 
        / LAG(SUM(order_total), 1) OVER (ORDER BY DATE_TRUNC('month', order_date)) * 100 as growth_pct
FROM orders
GROUP BY DATE_TRUNC('month', order_date);
```

#### FIRST_VALUE() and LAST_VALUE()

```sql
SELECT 
    employee_id,
    first_name,
    department_id,
    salary,
    FIRST_VALUE(salary) OVER (PARTITION BY department_id ORDER BY salary DESC) as highest_dept_salary,
    LAST_VALUE(salary) OVER (
        PARTITION BY department_id 
        ORDER BY salary DESC
        ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
    ) as lowest_dept_salary
FROM employees;
```

> [!IMPORTANT]
> `LAST_VALUE()` requires careful window frame specification. Without `ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING`, it only considers rows up to the current row.

#### Running Totals and Moving Averages

```sql
SELECT 
    order_date,
    order_total,
    SUM(order_total) OVER (ORDER BY order_date) as running_total,
    AVG(order_total) OVER (
        ORDER BY order_date 
        ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
    ) as moving_avg_7days
FROM orders;
```

#### NTILE()

Divides rows into N buckets.

```sql
SELECT 
    employee_id,
    first_name,
    salary,
    NTILE(4) OVER (ORDER BY salary DESC) as salary_quartile
FROM employees;
```

**Use Case:** Segment customers into equal groups for analysis.

### 3.2 Recursive Queries

Recursive CTEs allow you to query hierarchical or tree-structured data.

#### Employee Hierarchy

```sql
WITH RECURSIVE employee_hierarchy AS (
    -- Anchor member: Start with top-level employees (no manager)
    SELECT 
        employee_id,
        first_name,
        last_name,
        manager_id,
        1 as level,
        CAST(first_name || ' ' || last_name AS VARCHAR(1000)) as hierarchy_path
    FROM employees
    WHERE manager_id IS NULL
    
    UNION ALL
    
    -- Recursive member: Find employees who report to current level
    SELECT 
        e.employee_id,
        e.first_name,
        e.last_name,
        e.manager_id,
        eh.level + 1,
        CAST(eh.hierarchy_path || ' -> ' || e.first_name || ' ' || e.last_name AS VARCHAR(1000))
    FROM employees e
    INNER JOIN employee_hierarchy eh ON e.manager_id = eh.employee_id
)
SELECT * FROM employee_hierarchy
ORDER BY hierarchy_path;
```

**Explanation:**
1. Anchor member finds starting points (employees with no manager)
2. Recursive member finds employees managed by people found in previous iteration
3. Process repeats until no more rows are found

#### Bill of Materials (BOM)

```sql
WITH RECURSIVE part_explosion AS (
    -- Start with the finished product
    SELECT 
        component_id,
        part_id,
        quantity,
        1 as level
    FROM bill_of_materials
    WHERE part_id = 'FINISHED_PRODUCT_ID'
    
    UNION ALL
    
    -- Find sub-components
    SELECT 
        bom.component_id,
        bom.part_id,
        bom.quantity * pe.quantity,
        pe.level + 1
    FROM bill_of_materials bom
    INNER JOIN part_explosion pe ON bom.part_id = pe.component_id
)
SELECT 
    component_id,
    SUM(quantity) as total_quantity_needed,
    MAX(level) as deepest_level
FROM part_explosion
GROUP BY component_id;
```

#### Finding Paths in a Graph

```sql
WITH RECURSIVE route_finder AS (
    -- Start at origin
    SELECT 
        origin,
        destination,
        distance,
        ARRAY[origin, destination] as path,
        distance as total_distance
    FROM flights
    WHERE origin = 'SFO'
    
    UNION ALL
    
    -- Find connecting flights
    SELECT 
        rf.origin,
        f.destination,
        f.distance,
        rf.path || f.destination,
        rf.total_distance + f.distance
    FROM route_finder rf
    INNER JOIN flights f ON rf.destination = f.origin
    WHERE NOT f.destination = ANY(rf.path)  -- Avoid cycles
      AND array_length(rf.path, 1) < 5  -- Limit path length
)
SELECT * FROM route_finder
WHERE destination = 'JFK'
ORDER BY total_distance
LIMIT 5;
```

> [!CAUTION]
> Recursive queries can run indefinitely or consume excessive resources. Always include termination conditions (depth limits, cycle detection).

### 3.3 Pivot and Unpivot Operations

#### PIVOT - Rows to Columns

```sql
-- Manual pivot using CASE
SELECT 
    product_category,
    SUM(CASE WHEN EXTRACT(QUARTER FROM sale_date) = 1 THEN sale_amount ELSE 0 END) as Q1_sales,
    SUM(CASE WHEN EXTRACT(QUARTER FROM sale_date) = 2 THEN sale_amount ELSE 0 END) as Q2_sales,
    SUM(CASE WHEN EXTRACT(QUARTER FROM sale_date) = 3 THEN sale_amount ELSE 0 END) as Q3_sales,
    SUM(CASE WHEN EXTRACT(QUARTER FROM sale_date) = 4 THEN sale_amount ELSE 0 END) as Q4_sales
FROM sales
GROUP BY product_category;
```

```sql
-- Using CROSSTAB (PostgreSQL extension)
SELECT * FROM crosstab(
    'SELECT product_category, quarter, SUM(sale_amount)
     FROM sales
     GROUP BY product_category, quarter
     ORDER BY product_category, quarter',
    'SELECT DISTINCT quarter FROM sales ORDER BY quarter'
) AS ct(product_category text, Q1 numeric, Q2 numeric, Q3 numeric, Q4 numeric);
```

#### UNPIVOT - Columns to Rows

```sql
-- Manual unpivot using UNION ALL
SELECT product_category, 'Q1' as quarter, Q1_sales as sales FROM quarterly_sales
UNION ALL
SELECT product_category, 'Q2', Q2_sales FROM quarterly_sales
UNION ALL
SELECT product_category, 'Q3', Q3_sales FROM quarterly_sales
UNION ALL
SELECT product_category, 'Q4', Q4_sales FROM quarterly_sales;
```

### 3.4 Advanced Grouping: ROLLUP, CUBE, GROUPING SETS

#### ROLLUP

Creates subtotals and grand totals.

```sql
SELECT 
    region,
    product_category,
    SUM(sales_amount) as total_sales
FROM sales
GROUP BY ROLLUP (region, product_category);
```

**Result includes:**
- Each (region, product_category) combination
- Subtotals for each region (all categories)
- Grand total (all regions and categories)

#### CUBE

Creates all possible combinations of groupings.

```sql
SELECT 
    region,
    product_category,
    customer_segment,
    SUM(sales_amount) as total_sales
FROM sales
GROUP BY CUBE (region, product_category, customer_segment);
```

**Result includes all combinations:**
- (region, product_category, customer_segment)
- (region, product_category)
- (region, customer_segment)
- (product_category, customer_segment)
- (region), (product_category), (customer_segment)
- Grand total

#### GROUPING SETS

Specify exactly which groupings you want.

```sql
SELECT 
    region,
    product_category,
    SUM(sales_amount) as total_sales
FROM sales
GROUP BY GROUPING SETS (
    (region, product_category),
    (region),
    ()
);
```

#### GROUPING() Function

Identify which rows are aggregates.

```sql
SELECT 
    region,
    product_category,
    SUM(sales_amount) as total_sales,
    GROUPING(region) as is_region_total,
    GROUPING(product_category) as is_category_total,
    CASE 
        WHEN GROUPING(region) = 1 AND GROUPING(product_category) = 1 THEN 'Grand Total'
        WHEN GROUPING(region) = 1 THEN 'Region Total'
        WHEN GROUPING(product_category) = 1 THEN 'Category Total'
        ELSE 'Detail'
    END as aggregation_level
FROM sales
GROUP BY ROLLUP (region, product_category);
```

### 3.5 JSON and Semi-Structured Data

Modern databases support JSON data types and querying.

```sql
-- PostgreSQL JSON operations
SELECT 
    order_id,
    metadata->>'customer_name' as customer_name,
    metadata->>'shipping_address' as shipping_address,
    (metadata->'items')::json as items
FROM orders
WHERE metadata->>'status' = 'shipped';

-- Extract array elements
SELECT 
    order_id,
    jsonb_array_elements(metadata->'items') as item
FROM orders;

-- Aggregate to JSON
SELECT 
    department_id,
    json_agg(json_build_object(
        'employee_id', employee_id,
        'name', first_name || ' ' || last_name,
        'salary', salary
    )) as employees
FROM employees
GROUP BY department_id;
```

---

## Performance Optimization

### 4.1 Understanding Query Execution

#### Query Execution Order

```sql
SELECT DISTINCT column_list      -- 5. Select and remove duplicates
FROM table_name                  -- 1. Choose table(s)
WHERE conditions                 -- 2. Filter rows
GROUP BY columns                 -- 3. Group rows
HAVING group_conditions          -- 4. Filter groups
ORDER BY columns                 -- 6. Sort results
LIMIT n OFFSET m;               -- 7. Limit rows
```

#### Explain Plans

Use `EXPLAIN` to understand how the database executes your query.

```sql
EXPLAIN SELECT * FROM employees WHERE department_id = 10;

EXPLAIN ANALYZE SELECT * FROM employees WHERE department_id = 10;
```

**Key metrics to examine:**
- **Seq Scan:** Full table scan (potentially slow on large tables)
- **Index Scan:** Using an index (usually faster)
- **Cost:** Estimated execution cost
- **Rows:** Estimated number of rows
- **Actual time:** Real execution time (with ANALYZE)

**Example output:**
```
Index Scan using idx_dept_id on employees  (cost=0.29..8.31 rows=1 width=48)
  Index Cond: (department_id = 10)
```

### 4.2 Indexes - The Foundation of Performance

Indexes are data structures that improve query performance by allowing fast lookups.

#### B-Tree Indexes (Default)

Best for exact matches and range queries.

```sql
-- Single column index
CREATE INDEX idx_employee_lastname ON employees(last_name);

-- Multi-column index
CREATE INDEX idx_employee_dept_salary ON employees(department_id, salary);

-- Unique index
CREATE UNIQUE INDEX idx_employee_email ON employees(email);
```

**When to use:**
- Columns frequently in `WHERE`, `JOIN`, `ORDER BY` clauses
- Foreign key columns
- Columns with high selectivity (many unique values)

**Multi-column index considerations:**
```sql
CREATE INDEX idx_dept_salary ON employees(department_id, salary);

-- This query uses the index
SELECT * FROM employees WHERE department_id = 10 AND salary > 50000;

-- This query uses the index (leftmost column)
SELECT * FROM employees WHERE department_id = 10;

-- This query does NOT use the index efficiently (missing leftmost column)
SELECT * FROM employees WHERE salary > 50000;
```

> [!IMPORTANT]
> Index column order matters! Place the most selective or frequently queried columns first.

#### Partial Indexes

Index only a subset of rows.

```sql
CREATE INDEX idx_active_employees ON employees(last_name)
WHERE status = 'active';
```

**Benefits:**
- Smaller index size
- Faster index operations
- Useful when most queries filter on the same condition

#### Expression Indexes

Index computed values.

```sql
CREATE INDEX idx_lower_email ON employees(LOWER(email));

-- Now this query uses the index
SELECT * FROM employees WHERE LOWER(email) = 'john@example.com';
```

#### Covering Indexes

Include all columns needed by a query to avoid accessing the table.

```sql
CREATE INDEX idx_employee_covering 
ON employees(department_id) 
INCLUDE (first_name, last_name, salary);

-- This query only needs the index (no table lookup)
SELECT first_name, last_name, salary 
FROM employees 
WHERE department_id = 10;
```

#### Hash Indexes

Only support equality operations, faster than B-tree for exact matches.

```sql
CREATE INDEX idx_employee_id_hash ON employees USING HASH (employee_id);
```

> [!NOTE]
> Hash indexes are not as commonly used and aren't available in all databases. B-tree indexes usually suffice.

#### Full-Text Indexes

For text search operations.

```sql
-- PostgreSQL
CREATE INDEX idx_product_description ON products USING GIN (to_tsvector('english', description));

SELECT * FROM products 
WHERE to_tsvector('english', description) @@ to_tsquery('database & performance');
```

#### Index Maintenance

```sql
-- View indexes on a table
SELECT indexname, indexdef 
FROM pg_indexes 
WHERE tablename = 'employees';

-- Drop unused index
DROP INDEX idx_employee_old;

-- Rebuild index
REINDEX INDEX idx_employee_lastname;
```

> [!WARNING]
> Too many indexes slow down INSERT, UPDATE, and DELETE operations. Index strategically based on your query patterns.

### 4.3 Query Optimization Techniques

#### Use Appropriate JOINs

```sql
-- INEFFICIENT: Filtering in WHERE after JOIN
SELECT e.*, d.*
FROM employees e
LEFT JOIN departments d ON e.department_id = d.department_id
WHERE e.salary > 60000;

-- BETTER: Filter before JOIN
SELECT e.*, d.*
FROM (SELECT * FROM employees WHERE salary > 60000) e
LEFT JOIN departments d ON e.department_id = d.department_id;

-- BEST: Let the optimizer handle it with proper indexes
SELECT e.*, d.*
FROM employees e
LEFT JOIN departments d ON e.department_id = d.department_id
WHERE e.salary > 60000;
-- With index on employees(salary), this is optimal
```

#### EXISTS vs IN

```sql
-- For large right-side tables, EXISTS is often faster
SELECT * FROM customers c
WHERE EXISTS (
    SELECT 1 FROM orders o 
    WHERE o.customer_id = c.customer_id
);

-- IN can be faster for small right-side tables
SELECT * FROM customers
WHERE customer_id IN (
    SELECT DISTINCT customer_id FROM orders
);
```

#### Avoid SELECT *

```sql
-- INEFFICIENT
SELECT * FROM employees;

-- EFFICIENT: Only select needed columns
SELECT employee_id, first_name, last_name FROM employees;
```

**Benefits:**
- Reduced network traffic
- Smaller result set
- Enables covering indexes
- Clearer code intent

#### Use LIMIT When Appropriate

```sql
-- If you only need a few rows, use LIMIT
SELECT * FROM orders 
ORDER BY order_date DESC 
LIMIT 10;
```

#### Avoid Functions on Indexed Columns in WHERE

```sql
-- INEFFICIENT: Index cannot be used
SELECT * FROM employees 
WHERE YEAR(hire_date) = 2024;

-- EFFICIENT: Index can be used
SELECT * FROM employees 
WHERE hire_date >= '2024-01-01' AND hire_date < '2025-01-01';
```

#### Optimize OR Conditions

```sql
-- INEFFICIENT: May not use indexes effectively
SELECT * FROM employees 
WHERE department_id = 10 OR department_id = 20;

-- EFFICIENT: Use IN
SELECT * FROM employees 
WHERE department_id IN (10, 20);

-- For different columns with OR
-- INEFFICIENT
SELECT * FROM employees 
WHERE department_id = 10 OR salary > 80000;

-- EFFICIENT: Use UNION ALL
SELECT * FROM employees WHERE department_id = 10
UNION ALL
SELECT * FROM employees WHERE salary > 80000 AND department_id != 10;
```

#### Batch Operations

```sql
-- INEFFICIENT: Multiple single-row inserts
INSERT INTO employees VALUES (1, 'John', 'Doe');
INSERT INTO employees VALUES (2, 'Jane', 'Smith');
INSERT INTO employees VALUES (3, 'Bob', 'Johnson');

-- EFFICIENT: Batch insert
INSERT INTO employees VALUES 
    (1, 'John', 'Doe'),
    (2, 'Jane', 'Smith'),
    (3, 'Bob', 'Johnson');
```

#### Use Appropriate Data Types

```sql
-- INEFFICIENT: Using VARCHAR for numbers
CREATE TABLE orders (
    order_id VARCHAR(20),
    quantity VARCHAR(10)
);

-- EFFICIENT: Use appropriate types
CREATE TABLE orders (
    order_id BIGINT,
    quantity INTEGER
);
```

**Benefits:**
- Smaller storage
- Faster comparisons
- Index efficiency
- Data integrity

### 4.4 JOIN Optimization

#### Join Order Matters

The database optimizer usually handles this, but understanding helps:

```sql
-- Join smaller result sets first
SELECT *
FROM large_table l
INNER JOIN (
    SELECT * FROM medium_table WHERE active = true
) m ON l.id = m.id
INNER JOIN small_table s ON m.category_id = s.category_id;
```

#### Index JOIN Columns

```sql
-- Ensure indexes exist on both sides of JOIN
CREATE INDEX idx_orders_customer_id ON orders(customer_id);
CREATE INDEX idx_customers_id ON customers(customer_id);

SELECT *
FROM orders o
INNER JOIN customers c ON o.customer_id = c.customer_id;
```

#### Avoid Implicit Cartesian Products

```sql
-- INEFFICIENT: Cartesian product (all combinations)
SELECT *
FROM employees, departments
WHERE employees.salary > 50000;

-- EFFICIENT: Proper JOIN
SELECT *
FROM employees e
INNER JOIN departments d ON e.department_id = d.department_id
WHERE e.salary > 50000;
```

### 4.5 Partitioning for Large Tables

Partitioning divides a large table into smaller, more manageable pieces.

#### Range Partitioning

```sql
-- Create partitioned table
CREATE TABLE orders (
    order_id BIGINT,
    customer_id INT,
    order_date DATE,
    total NUMERIC(10,2)
) PARTITION BY RANGE (order_date);

-- Create partitions
CREATE TABLE orders_2023 PARTITION OF orders
    FOR VALUES FROM ('2023-01-01') TO ('2024-01-01');

CREATE TABLE orders_2024 PARTITION OF orders
    FOR VALUES FROM ('2024-01-01') TO ('2025-01-01');

CREATE TABLE orders_2025 PARTITION OF orders
    FOR VALUES FROM ('2025-01-01') TO ('2026-01-01');
```

**Benefits:**
- Query performance (partition pruning)
- Easier data management (drop old partitions)
- Improved maintenance (vacuum, reindex specific partitions)

#### List Partitioning

```sql
CREATE TABLE sales (
    sale_id BIGINT,
    region VARCHAR(50),
    amount NUMERIC(10,2)
) PARTITION BY LIST (region);

CREATE TABLE sales_north PARTITION OF sales
    FOR VALUES IN ('North', 'Northeast', 'Northwest');

CREATE TABLE sales_south PARTITION OF sales
    FOR VALUES IN ('South', 'Southeast', 'Southwest');
```

#### Hash Partitioning

```sql
CREATE TABLE users (
    user_id BIGINT,
    username VARCHAR(100),
    email VARCHAR(255)
) PARTITION BY HASH (user_id);

CREATE TABLE users_0 PARTITION OF users
    FOR VALUES WITH (MODULUS 4, REMAINDER 0);

CREATE TABLE users_1 PARTITION OF users
    FOR VALUES WITH (MODULUS 4, REMAINDER 1);

CREATE TABLE users_2 PARTITION OF users
    FOR VALUES WITH (MODULUS 4, REMAINDER 2);

CREATE TABLE users_3 PARTITION OF users
    FOR VALUES WITH (MODULUS 4, REMAINDER 3);
```

**Use case:** Evenly distribute data across partitions.

### 4.6 Materialized Views

Materialized views pre-compute and store query results.

```sql
-- Create materialized view
CREATE MATERIALIZED VIEW mv_department_stats AS
SELECT 
    d.department_id,
    d.department_name,
    COUNT(e.employee_id) as employee_count,
    AVG(e.salary) as avg_salary,
    MAX(e.salary) as max_salary
FROM departments d
LEFT JOIN employees e ON d.department_id = e.department_id
GROUP BY d.department_id, d.department_name;

-- Create index on materialized view
CREATE INDEX idx_mv_dept_stats_dept_id ON mv_department_stats(department_id);

-- Query materialized view (fast!)
SELECT * FROM mv_department_stats WHERE employee_count > 10;

-- Refresh materialized view
REFRESH MATERIALIZED VIEW mv_department_stats;

-- Refresh without blocking reads (PostgreSQL 9.4+)
REFRESH MATERIALIZED VIEW CONCURRENTLY mv_department_stats;
```

**Use cases:**
- Complex aggregations used frequently
- Reports and dashboards
- Data from multiple tables
- When slight staleness is acceptable

> [!TIP]
> Schedule refreshes during off-peak hours or use incremental refresh strategies for large views.

---

## Scalability Best Practices

### 5.1 Database Design for Scale

#### Normalization

Organize data to reduce redundancy and improve integrity.

**First Normal Form (1NF):**
- Atomic values (no repeating groups)
- Each column contains one value

**Second Normal Form (2NF):**
- Meets 1NF
- No partial dependencies (all non-key columns depend on the entire primary key)

**Third Normal Form (3NF):**
- Meets 2NF
- No transitive dependencies (non-key columns don't depend on other non-key columns)

**Example:**

```sql
-- Not normalized
CREATE TABLE orders (
    order_id INT,
    customer_name VARCHAR(100),
    customer_email VARCHAR(100),
    customer_phone VARCHAR(20),
    product1_id INT,
    product1_name VARCHAR(100),
    product1_price NUMERIC,
    product2_id INT,
    product2_name VARCHAR(100),
    product2_price NUMERIC
);

-- Normalized (3NF)
CREATE TABLE customers (
    customer_id INT PRIMARY KEY,
    customer_name VARCHAR(100),
    email VARCHAR(100),
    phone VARCHAR(20)
);

CREATE TABLE orders (
    order_id INT PRIMARY KEY,
    customer_id INT REFERENCES customers(customer_id),
    order_date DATE
);

CREATE TABLE products (
    product_id INT PRIMARY KEY,
    product_name VARCHAR(100),
    price NUMERIC
);

CREATE TABLE order_items (
    order_id INT REFERENCES orders(order_id),
    product_id INT REFERENCES products(product_id),
    quantity INT,
    PRIMARY KEY (order_id, product_id)
);
```

#### Denormalization for Performance

Sometimes breaking normalization rules improves performance.

```sql
-- Add denormalized column for frequently accessed data
CREATE TABLE orders (
    order_id INT PRIMARY KEY,
    customer_id INT REFERENCES customers(customer_id),
    customer_name VARCHAR(100),  -- Denormalized from customers table
    order_date DATE,
    total_amount NUMERIC  -- Denormalized aggregate from order_items
);
```

> [!WARNING]
> Denormalization introduces data redundancy and update complexity. Only denormalize when performance gains justify the maintenance cost.

### 5.2 Connection Pooling

Connection pooling reuses database connections instead of creating new ones for each request.

**Benefits:**
- Reduced connection overhead
- Better resource utilization
- Improved application performance

**Configuration example (application-level):**
```javascript
// Node.js with pg
const { Pool } = require('pg');
const pool = new Pool({
    host: 'localhost',
    database: 'mydb',
    max: 20,  // Maximum pool size
    min: 5,   // Minimum pool size
    idleTimeoutMillis: 30000
});
```

### 5.3 Read Replicas

Distribute read load across multiple database copies.

```sql
-- Application pseudo-code
if (query.isReadOnly()) {
    connection = readReplicaPool.getConnection();
} else {
    connection = primaryPool.getConnection();
}
```

**Architecture:**
- Primary database: Handles all writes
- Read replicas: Handle read queries
- Replication: Asynchronous data sync from primary to replicas

**Benefits:**
- Horizontal scaling for reads
- Improved read performance
- High availability

> [!IMPORTANT]
> Read replicas have replication lag. Data might be slightly stale.

### 5.4 Sharding

Distribute data across multiple database instances.

#### Horizontal Sharding Example

```sql
-- Shard by customer_id
-- Shard 1: customer_id % 3 = 0
-- Shard 2: customer_id % 3 = 1
-- Shard 3: customer_id % 3 = 2

def get_shard_for_customer(customer_id):
    shard_num = customer_id % 3
    return database_connections[shard_num]
```

**Challenges:**
- Cross-shard queries are complex
- Resharding is difficult
- Application complexity increases

**When to consider:**
- Database size exceeds single server capacity
- Write load exceeds single server capacity
- Geographic distribution requirements

### 5.5 Caching Strategies

#### Query Result Caching

```javascript
// Application-level caching
const cache = require('redis').createClient();

async function getDepartmentStats(deptId) {
    const cacheKey = `dept_stats:${deptId}`;
    
    // Try cache first
    const cached = await cache.get(cacheKey);
    if (cached) return JSON.parse(cached);
    
    // Query database
    const result = await db.query(
        'SELECT * FROM mv_department_stats WHERE department_id = $1',
        [deptId]
    );
    
    // Cache for 5 minutes
    await cache.setex(cacheKey, 300, JSON.stringify(result));
    return result;
}
```

#### Database-Level Caching

Most databases have built-in query caching and buffer pools.

```sql
-- PostgreSQL: Increase shared buffers
-- postgresql.conf
shared_buffers = 4GB

-- Monitor cache hit ratio
SELECT 
    sum(heap_blks_read) as heap_read,
    sum(heap_blks_hit) as heap_hit,
    sum(heap_blks_hit) / (sum(heap_blks_hit) + sum(heap_blks_read)) as cache_hit_ratio
FROM pg_statio_user_tables;
```

> [!TIP]
> Aim for a cache hit ratio above 0.99 (99%) for optimal performance.

### 5.6 Batch Processing

Process large datasets in batches to avoid overwhelming resources.

```sql
-- Process in batches
DO $$
DECLARE
    batch_size INT := 1000;
    offset_val INT := 0;
    rows_affected INT;
BEGIN
    LOOP
        UPDATE large_table
        SET status = 'processed'
        WHERE id IN (
            SELECT id FROM large_table
            WHERE status = 'pending'
            LIMIT batch_size
            OFFSET offset_val
        );
        
        GET DIAGNOSTICS rows_affected = ROW_COUNT;
        EXIT WHEN rows_affected = 0;
        
        offset_val := offset_val + batch_size;
        COMMIT;  -- Commit each batch
    END LOOP;
END $$;
```

### 5.7 Asynchronous Processing

Move heavy queries to background jobs.

```sql
-- Instead of running expensive query synchronously:
-- Create a job queue
CREATE TABLE report_jobs (
    job_id SERIAL PRIMARY KEY,
    user_id INT,
    status VARCHAR(20),
    created_at TIMESTAMP,
    completed_at TIMESTAMP,
    result_location TEXT
);

-- Worker process runs expensive query
INSERT INTO report_jobs (user_id, status, created_at)
VALUES (123, 'pending', NOW());

-- Background worker picks up job, runs query, stores result
```

---

## Query Analysis and Troubleshooting

### 6.1 Identifying Slow Queries

#### Enable Query Logging

```sql
-- PostgreSQL: Log slow queries (postgresql.conf)
log_min_duration_statement = 1000  -- Log queries taking > 1 second

-- View slow query log
SELECT * FROM pg_stat_statements
ORDER BY total_exec_time DESC
LIMIT 10;
```

#### Monitoring Query Performance

```sql
-- PostgreSQL: Query statistics
SELECT 
    query,
    calls,
    total_exec_time,
    mean_exec_time,
    max_exec_time
FROM pg_stat_statements
ORDER BY mean_exec_time DESC
LIMIT 20;
```

### 6.2 Reading Execution Plans

```sql
EXPLAIN ANALYZE
SELECT e.first_name, e.last_name, d.department_name
FROM employees e
INNER JOIN departments d ON e.department_id = d.department_id
WHERE e.salary > 60000;
```

**Key elements:**
- **Seq Scan**: Full table scan (consider adding index)
- **Index Scan**: Using index (good)
- **Nested Loop**: Join method for small tables
- **Hash Join**: Join method for larger tables
- **Merge Join**: Join method when both sides are sorted
- **Cost**: Estimated execution cost
- **Rows**: Estimated rows processed
- **Actual time**: Real execution time

**Example output analysis:**
```
Hash Join  (cost=15.50..35.25 rows=100 width=64) (actual time=0.123..0.456 rows=98 loops=1)
    Hash Cond: (e.department_id = d.department_id)
    ->  Seq Scan on employees e  (cost=0.00..18.00 rows=100 width=40) (actual time=0.012..0.234 rows=98 loops=1)
          Filter: (salary > 60000::numeric)
          Rows Removed by Filter: 402
    ->  Hash  (cost=12.00..12.00 rows=200 width=24) (actual time=0.089..0.090 rows=10 loops=1)
          ->  Seq Scan on departments d  (cost=0.00..12.00 rows=200 width=24)
```

**Analysis:**
- Hash join chosen (appropriate for this size)
- Sequential scan on employees filters by salary (consider index on salary)
- 402 rows filtered out (low selectivity)

### 6.3 Common Performance Problems

#### Problem: Full Table Scan on Large Table

```sql
-- Symptom: Seq Scan in EXPLAIN
EXPLAIN SELECT * FROM large_table WHERE status = 'active';

-- Solution: Add index
CREATE INDEX idx_large_table_status ON large_table(status);
```

#### Problem: Index Not Being Used

```sql
-- Query using function on indexed column
SELECT * FROM employees WHERE UPPER(last_name) = 'SMITH';

-- Solution: Expression index
CREATE INDEX idx_employees_upper_lastname ON employees(UPPER(last_name));
```

#### Problem: N+1 Query Problem

```sql
-- INEFFICIENT: One query per department
for dept_id in department_ids:
    SELECT * FROM employees WHERE department_id = dept_id;

-- EFFICIENT: Single query
SELECT * FROM employees 
WHERE department_id IN (1, 2, 3, 4, 5);
```

#### Problem: Missing JOIN Condition

```sql
-- INEFFICIENT: Cartesian product
SELECT * FROM employees, departments;

-- EFFICIENT: Proper JOIN
SELECT * FROM employees e
INNER JOIN departments d ON e.department_id = d.department_id;
```

#### Problem: Outdated Statistics

```sql
-- Database optimizer uses outdated statistics
-- Solution: Update statistics
ANALYZE employees;

-- Or for entire database
ANALYZE;
```

### 6.4 Query Optimization Workflow

1. **Identify slow query** (monitoring, logs)
2. **Get execution plan** (`EXPLAIN ANALYZE`)
3. **Identify bottleneck** (scans, joins, sorts)
4. **Apply fix** (index, rewrite, denormalize)
5. **Verify improvement** (re-run `EXPLAIN ANALYZE`)
6. **Monitor in production** (ensure consistent performance)

---

## Real-World Patterns and Anti-Patterns

### 7.1 Design Patterns

#### Soft Deletes

```sql
-- Add deleted_at column
ALTER TABLE employees ADD COLUMN deleted_at TIMESTAMP;

-- "Delete" records
UPDATE employees SET deleted_at = NOW() WHERE employee_id = 123;

-- Query only active records
SELECT * FROM employees WHERE deleted_at IS NULL;

-- Create filtered index
CREATE INDEX idx_employees_active ON employees(employee_id) 
WHERE deleted_at IS NULL;
```

#### Audit Trails

```sql
CREATE TABLE employee_audit (
    audit_id SERIAL PRIMARY KEY,
    employee_id INT,
    operation VARCHAR(10),
    changed_at TIMESTAMP DEFAULT NOW(),
    changed_by VARCHAR(100),
    old_values JSONB,
    new_values JSONB
);

-- Trigger for automatic auditing
CREATE OR REPLACE FUNCTION audit_employee_changes()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO employee_audit (employee_id, operation, old_values, new_values)
    VALUES (
        COALESCE(NEW.employee_id, OLD.employee_id),
        TG_OP,
        to_jsonb(OLD),
        to_jsonb(NEW)
    );
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER employee_audit_trigger
AFTER INSERT OR UPDATE OR DELETE ON employees
FOR EACH ROW EXECUTE FUNCTION audit_employee_changes();
```

#### Temporal Tables (Versioning)

```sql
CREATE TABLE products (
    product_id INT,
    name VARCHAR(100),
    price NUMERIC,
    valid_from TIMESTAMP DEFAULT NOW(),
    valid_to TIMESTAMP DEFAULT '9999-12-31'::TIMESTAMP,
    PRIMARY KEY (product_id, valid_from)
);

-- Query current version
SELECT * FROM products 
WHERE product_id = 123 
  AND valid_to = '9999-12-31'::TIMESTAMP;

-- Query historical version
SELECT * FROM products 
WHERE product_id = 123 
  AND '2024-06-15'::TIMESTAMP BETWEEN valid_from AND valid_to;
```

#### Hierarchical Data (Materialized Path)

```sql
CREATE TABLE categories (
    category_id INT PRIMARY KEY,
    name VARCHAR(100),
    path VARCHAR(500)  -- e.g., '1.3.7' for root>parent>child
);

-- Find all descendants
SELECT * FROM categories 
WHERE path LIKE '1.3.%';

-- Find all ancestors
WITH paths AS (
    SELECT unnest(string_to_array(path, '.')) as ancestor_id
    FROM categories
    WHERE category_id = 7
)
SELECT c.* FROM categories c
INNER JOIN paths p ON c.category_id::TEXT = p.ancestor_id;
```

### 7.2 Anti-Patterns to Avoid

#### Anti-Pattern: Entity-Attribute-Value (EAV)

```sql
-- AVOID THIS: EAV Schema
CREATE TABLE entity_attributes (
    entity_id INT,
    attribute_name VARCHAR(100),
    attribute_value TEXT
);

-- Queries become complex and slow
SELECT 
    MAX(CASE WHEN attribute_name = 'first_name' THEN attribute_value END) as first_name,
    MAX(CASE WHEN attribute_name = 'last_name' THEN attribute_value END) as last_name,
    MAX(CASE WHEN attribute_name = 'email' THEN attribute_value END) as email
FROM entity_attributes
WHERE entity_id = 123
GROUP BY entity_id;

-- BETTER: Proper columns or JSON
CREATE TABLE entities (
    entity_id INT PRIMARY KEY,
    first_name VARCHAR(100),
    last_name VARCHAR(100),
    email VARCHAR(255),
    additional_attributes JSONB  -- For truly dynamic attributes
);
```

#### Anti-Pattern: Implicit Column Behavior

```sql
-- AVOID: Relying on column order
INSERT INTO employees VALUES (1, 'John', 'Doe', 50000);

-- BETTER: Explicit columns
INSERT INTO employees (employee_id, first_name, last_name, salary)
VALUES (1, 'John', 'Doe', 50000);
```

#### Anti-Pattern: Too Many Joins

```sql
-- AVOID: Excessive joins in single query
SELECT *
FROM table1 t1
JOIN table2 t2 ON t1.id = t2.t1_id
JOIN table3 t3 ON t2.id = t3.t2_id
JOIN table4 t4 ON t3.id = t4.t3_id
JOIN table5 t5 ON t4.id = t5.t4_id
JOIN table6 t6 ON t5.id = t6.t5_id
JOIN table7 t7 ON t6.id = t7.t6_id;

-- BETTER: Break into multiple queries or use CTEs
WITH base_data AS (
    SELECT * FROM table1 t1
    JOIN table2 t2 ON t1.id = t2.t1_id
    JOIN table3 t3 ON t2.id = t3.t2_id
),
extended_data AS (
    SELECT bd.*, t4.*
    FROM base_data bd
    JOIN table4 t4 ON bd.id = t4.bd_id
)
SELECT * FROM extended_data;
```

#### Anti-Pattern: Generic "Status" Flags

```sql
-- AVOID: Magic numbers
CREATE TABLE orders (
    order_id INT,
    status INT  -- What does 1, 2, 3 mean?
);

-- BETTER: Enums or descriptive values
CREATE TYPE order_status AS ENUM ('pending', 'processing', 'shipped', 'delivered', 'cancelled');

CREATE TABLE orders (
    order_id INT,
    status order_status
);
```

#### Anti-Pattern: Fear of Write Operations

```sql
-- AVOID: Over-querying to avoid updates
SELECT status FROM orders WHERE order_id = 123;
-- Check in application code
if status != 'shipped':
    UPDATE orders SET status = 'shipped' WHERE order_id = 123;

-- BETTER: Let database handle it
UPDATE orders 
SET status = 'shipped' 
WHERE order_id = 123 AND status != 'shipped';
-- Returns 0 rows if already shipped
```

### 7.3 Transaction Best Practices

```sql
-- Keep transactions short
BEGIN;
    UPDATE accounts SET balance = balance - 100 WHERE account_id = 1;
    UPDATE accounts SET balance = balance + 100 WHERE account_id = 2;
COMMIT;

-- Use appropriate isolation level
BEGIN TRANSACTION ISOLATION LEVEL READ COMMITTED;
    -- Your queries
COMMIT;

-- Handle errors
BEGIN;
    UPDATE inventory SET quantity = quantity - 1 WHERE product_id = 123;
    
    -- Check if update affected rows
    IF NOT FOUND THEN
        ROLLBACK;
        RAISE EXCEPTION 'Product not found';
    END IF;
    
    INSERT INTO order_items (order_id, product_id, quantity) VALUES (456, 123, 1);
COMMIT;
```

### 7.4 Security Best Practices

#### Always Use Parameterized Queries

```sql
-- VULNERABLE to SQL injection
query = f"SELECT * FROM users WHERE email = '{user_input}'"

-- SAFE: Parameterized query
query = "SELECT * FROM users WHERE email = $1"
execute(query, [user_input])
```

#### Principle of Least Privilege

```sql
-- Create read-only user for reporting
CREATE USER reporting_user WITH PASSWORD 'secure_password';
GRANT SELECT ON ALL TABLES IN SCHEMA public TO reporting_user;

-- Create application user with specific permissions
CREATE USER app_user WITH PASSWORD 'secure_password';
GRANT SELECT, INSERT, UPDATE ON specific_tables TO app_user;
```

#### Row-Level Security

```sql
-- Enable row-level security
ALTER TABLE documents ENABLE ROW LEVEL SECURITY;

-- Create policy
CREATE POLICY document_access_policy ON documents
    FOR ALL
    TO app_user
    USING (owner_id = current_user_id());
```

---

## Database Programming: Transactions, Stored Procedures, and Triggers

### 8.1 Transactions - Deep Dive

Transactions are fundamental units of work that ensure data consistency and integrity.

#### ACID Properties

Transactions guarantee four critical properties:

**Atomicity:**
- All operations in a transaction succeed or all fail
- No partial updates
- Transaction is indivisible

**Consistency:**
- Database moves from one valid state to another
- All constraints are satisfied
- Business rules are maintained

**Isolation:**
- Concurrent transactions don't interfere with each other
- Each transaction appears to execute in isolation
- Controlled by isolation levels

**Durability:**
- Committed changes are permanent
- Survive system crashes
- Written to persistent storage

#### Basic Transaction Syntax

```sql
-- PostgreSQL/MySQL/SQL Server
BEGIN; -- or START TRANSACTION;
    UPDATE accounts SET balance = balance - 100 WHERE account_id = 1;
    UPDATE accounts SET balance = balance + 100 WHERE account_id = 2;
COMMIT;

-- Rollback on error
BEGIN;
    UPDATE inventory SET quantity = quantity - 5 WHERE product_id = 123;
    
    -- If something goes wrong
    ROLLBACK;
```

#### Transaction States

```sql
-- Active: Transaction is executing
BEGIN;
    -- Transaction is now ACTIVE
    INSERT INTO orders (customer_id, total) VALUES (1, 150.00);
    
-- Partially Committed: Final statement executed
    INSERT INTO order_items (order_id, product_id) VALUES (1001, 456);
    
-- Committed: Changes are permanent
COMMIT;

-- Failed/Aborted: Error occurred
BEGIN;
    UPDATE products SET price = -10 WHERE product_id = 1; -- Violates CHECK constraint
    -- Transaction automatically ABORTED
ROLLBACK;
```

#### Isolation Levels

Isolation levels control how transaction changes are visible to other concurrent transactions.

**READ UNCOMMITTED** - Lowest isolation, highest concurrency

```sql
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
BEGIN;
    SELECT * FROM accounts WHERE account_id = 1;
    -- Can read uncommitted changes from other transactions (dirty reads)
COMMIT;
```

**Problems:**
- Dirty reads: Reading uncommitted data
- Non-repeatable reads: Data changes between reads
- Phantom reads: New rows appear between reads

> [!CAUTION]
> READ UNCOMMITTED should rarely be used in production. Only appropriate for non-critical reporting where approximate data is acceptable.

**READ COMMITTED** - Default in most databases

```sql
SET TRANSACTION ISOLATION LEVEL READ COMMITTED;
BEGIN;
    SELECT balance FROM accounts WHERE account_id = 1; -- Reads committed data only
    -- Wait 5 seconds...
    SELECT balance FROM accounts WHERE account_id = 1; -- May see different value
COMMIT;
```

**Prevents:**
- Dirty reads ✓

**Allows:**
- Non-repeatable reads
- Phantom reads

**Use case:** Most OLTP applications, good balance of consistency and performance.

**REPEATABLE READ**

```sql
SET TRANSACTION ISOLATION LEVEL REPEATABLE READ;
BEGIN;
    SELECT * FROM accounts WHERE balance > 1000; -- Returns 5 rows
    -- Another transaction inserts a new account with balance 2000
    SELECT * FROM accounts WHERE balance > 1000; -- Still returns same 5 rows (phantom read prevented in PostgreSQL, but not in MySQL)
COMMIT;
```

**Prevents:**
- Dirty reads ✓
- Non-repeatable reads ✓

**Allows:**
- Phantom reads (in some databases)

**Use case:** Financial calculations, reports requiring consistent snapshot.

**SERIALIZABLE** - Highest isolation, lowest concurrency

```sql
SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;
BEGIN;
    SELECT SUM(balance) FROM accounts; -- Takes snapshot
    UPDATE accounts SET balance = balance * 1.05; -- 5% interest
    -- Completely isolated from other transactions
COMMIT;
```

**Prevents:**
- Dirty reads ✓
- Non-repeatable reads ✓
- Phantom reads ✓

**Trade-off:** Can cause significant performance degradation and deadlocks.

**Use case:** Critical operations requiring absolute consistency.

#### Isolation Level Comparison Table

| Isolation Level | Dirty Read | Non-Repeatable Read | Phantom Read | Performance |
|----------------|------------|---------------------|--------------|-------------|
| READ UNCOMMITTED | Yes | Yes | Yes | Fastest |
| READ COMMITTED | No | Yes | Yes | Fast |
| REPEATABLE READ | No | No | Yes* | Moderate |
| SERIALIZABLE | No | No | No | Slowest |

*PostgreSQL prevents phantom reads in REPEATABLE READ

#### Concurrency Control - Locking

**Pessimistic Locking:**

```sql
BEGIN;
    -- Exclusive lock: Prevents other transactions from reading/writing
    SELECT * FROM products WHERE product_id = 1 FOR UPDATE;
    
    -- Do some processing
    UPDATE products SET quantity = quantity - 1 WHERE product_id = 1;
COMMIT;

-- Shared lock: Allows reads, prevents writes
BEGIN;
    SELECT * FROM products WHERE product_id = 1 FOR SHARE;
    -- Other transactions can read but not modify
COMMIT;
```

**Lock Types:**

```sql
-- Row-level locks (PostgreSQL)
SELECT * FROM orders WHERE order_id = 123 FOR UPDATE; -- Exclusive
SELECT * FROM orders WHERE order_id = 123 FOR SHARE; -- Shared
SELECT * FROM orders WHERE order_id = 123 FOR UPDATE NOWAIT; -- Fail immediately if locked
SELECT * FROM orders WHERE order_id = 123 FOR UPDATE SKIP LOCKED; -- Skip locked rows

-- Table-level locks
LOCK TABLE products IN ACCESS EXCLUSIVE MODE; -- Most restrictive
LOCK TABLE products IN SHARE MODE; -- Allow concurrent reads
```

**Optimistic Locking:**

```sql
-- Using version column
CREATE TABLE products (
    product_id INT PRIMARY KEY,
    name VARCHAR(100),
    price NUMERIC,
    version INT DEFAULT 0
);

-- Application code
BEGIN;
    SELECT product_id, name, price, version 
    FROM products 
    WHERE product_id = 1;
    -- version = 5
    
    -- Update only if version hasn't changed
    UPDATE products 
    SET price = 29.99, version = version + 1
    WHERE product_id = 1 AND version = 5;
    
    -- If 0 rows updated, someone else modified it
    GET DIAGNOSTICS rows_affected = ROW_COUNT;
    IF rows_affected = 0 THEN
        ROLLBACK;
        RAISE EXCEPTION 'Concurrent modification detected';
    END IF;
COMMIT;
```

#### Deadlock Handling

**Deadlock Example:**

```sql
-- Transaction 1
BEGIN;
    UPDATE accounts SET balance = balance - 100 WHERE account_id = 1;
    -- Waiting for lock on account 2...
    UPDATE accounts SET balance = balance + 100 WHERE account_id = 2;
COMMIT;

-- Transaction 2 (running concurrently)
BEGIN;
    UPDATE accounts SET balance = balance - 50 WHERE account_id = 2;
    -- Waiting for lock on account 1... DEADLOCK!
    UPDATE accounts SET balance = balance + 50 WHERE account_id = 1;
COMMIT;
```

**Deadlock Prevention:**

```sql
-- 1. Always acquire locks in same order
BEGIN;
    -- Always lock lower account_id first
    UPDATE accounts SET balance = balance - 100 
    WHERE account_id = LEAST(1, 2);
    
    UPDATE accounts SET balance = balance + 100 
    WHERE account_id = GREATEST(1, 2);
COMMIT;

-- 2. Use shorter transactions
-- 3. Use appropriate isolation levels
-- 4. Handle deadlock exceptions in application code
```

**Deadlock Detection:**

```sql
-- PostgreSQL: View locks
SELECT 
    pid,
    usename,
    pg_blocking_pids(pid) as blocked_by,
    query
FROM pg_stat_activity
WHERE pg_blocking_pids(pid)::text != '{}';

-- Kill blocking transaction
SELECT pg_terminate_backend(pid);
```

#### Savepoints - Partial Rollback

```sql
BEGIN;
    INSERT INTO orders (customer_id, total) VALUES (1, 100.00);
    
    SAVEPOINT before_items;
    
    INSERT INTO order_items (order_id, product_id, quantity) 
    VALUES (1001, 1, 5);
    
    INSERT INTO order_items (order_id, product_id, quantity) 
    VALUES (1001, 2, 3);
    
    -- Something went wrong with items, rollback to savepoint
    ROLLBACK TO SAVEPOINT before_items;
    
    -- Order still exists, items are removed
    INSERT INTO order_items (order_id, product_id, quantity) 
    VALUES (1001, 3, 2); -- Insert different items
    
COMMIT;
```

#### Transaction Best Practices

> [!IMPORTANT]
> **Keep Transactions Short**
> - Minimize transaction duration
> - Reduce lock contention
> - Improve concurrency

```sql
-- BAD: Long transaction
BEGIN;
    SELECT * FROM large_table; -- Processes millions of rows
    -- Network call to external API
    -- Wait for user input
    UPDATE another_table SET status = 'processed';
COMMIT;

-- GOOD: Short, focused transaction
BEGIN;
    UPDATE accounts SET balance = balance - 100 WHERE account_id = 1;
    UPDATE accounts SET balance = balance + 100 WHERE account_id = 2;
COMMIT;
```

**Transaction Checklist:**

- [ ] Use appropriate isolation level
- [ ] Keep transactions as short as possible
- [ ] Acquire locks in consistent order
- [ ] Handle deadlocks gracefully
- [ ] Use savepoints for complex operations
- [ ] Avoid user interaction within transactions
- [ ] Don't call external services in transactions
- [ ] Use connection pooling
- [ ] Monitor transaction duration

#### Multi-Version Concurrency Control (MVCC)

PostgreSQL, MySQL InnoDB, and Oracle use MVCC for better concurrency.

```sql
-- Transaction 1
BEGIN;
    UPDATE accounts SET balance = 1000 WHERE account_id = 1;
    -- Not yet committed

-- Transaction 2 (concurrent)
BEGIN;
    SELECT balance FROM accounts WHERE account_id = 1;
    -- Sees old value (snapshot isolation)
    -- No blocking!
COMMIT;

-- Transaction 1
COMMIT; -- Changes now visible to new transactions
```

**Benefits:**
- Readers don't block writers
- Writers don't block readers
- Better concurrency than traditional locking

**Trade-off:**
- Requires VACUUM (PostgreSQL) to clean up old row versions
- More complex storage management

---

### 8.2 Stored Procedures

Stored procedures are precompiled SQL code stored in the database, executed as a single unit.

#### Why Use Stored Procedures?

**Benefits:**
- **Performance:** Pre-compiled and cached
- **Security:** Encapsulate logic, control access
- **Maintainability:** Centralize business logic
- **Network efficiency:** Reduce round trips
- **Reusability:** Called from multiple applications

**Drawbacks:**
- **Debugging:** Harder to debug than application code
- **Version control:** More complex than application code
- **Testing:** Requires database connection
- **Portability:** Database-specific syntax

#### Creating Stored Procedures

**PostgreSQL:**

```sql
CREATE OR REPLACE PROCEDURE transfer_funds(
    sender_account INT,
    receiver_account INT,
    amount NUMERIC
)
LANGUAGE plpgsql
AS $$
BEGIN
    -- Check sufficient balance
    IF (SELECT balance FROM accounts WHERE account_id = sender_account) < amount THEN
        RAISE EXCEPTION 'Insufficient funds';
    END IF;
    
    -- Debit sender
    UPDATE accounts 
    SET balance = balance - amount,
        updated_at = NOW()
    WHERE account_id = sender_account;
    
    -- Credit receiver
    UPDATE accounts 
    SET balance = balance + amount,
        updated_at = NOW()
    WHERE account_id = receiver_account;
    
    -- Log transaction
    INSERT INTO transaction_log (from_account, to_account, amount, timestamp)
    VALUES (sender_account, receiver_account, amount, NOW());
    
    COMMIT;
END;
$$;

-- Call the procedure
CALL transfer_funds(1, 2, 100.00);
```

**MySQL:**

```sql
DELIMITER //

CREATE PROCEDURE GetCustomerOrders(
    IN customer_id INT,
    OUT total_orders INT,
    OUT total_amount DECIMAL(10,2)
)
BEGIN
    SELECT 
        COUNT(*),
        SUM(total)
    INTO total_orders, total_amount
    FROM orders
    WHERE orders.customer_id = customer_id;
END //

DELIMITER ;

-- Call the procedure
CALL GetCustomerOrders(123, @order_count, @order_total);
SELECT @order_count, @order_total;
```

**SQL Server:**

```sql
CREATE PROCEDURE usp_GetEmployeesByDepartment
    @DepartmentID INT,
    @MinSalary DECIMAL(10,2) = 0 -- Default parameter value
AS
BEGIN
    SET NOCOUNT ON; -- Prevent extra result sets
    
    SELECT 
        employee_id,
        first_name,
        last_name,
        salary
    FROM employees
    WHERE department_id = @DepartmentID
      AND salary >= @MinSalary
    ORDER BY salary DESC;
END;
GO

-- Execute the procedure
EXEC usp_GetEmployeesByDepartment @DepartmentID = 10, @MinSalary = 50000;
```

#### Parameters: IN, OUT, INOUT

```sql
-- PostgreSQL
CREATE OR REPLACE PROCEDURE calculate_tax(
    IN gross_amount NUMERIC,
    IN tax_rate NUMERIC,
    OUT tax_amount NUMERIC,
    OUT net_amount NUMERIC
)
LANGUAGE plpgsql
AS $$
BEGIN
    tax_amount := gross_amount * tax_rate;
    net_amount := gross_amount - tax_amount;
END;
$$;

-- Call with OUT parameters
CALL calculate_tax(1000, 0.15, NULL, NULL);
```

#### Control Flow in Stored Procedures

**IF-THEN-ELSE:**

```sql
CREATE OR REPLACE PROCEDURE apply_discount(
    IN customer_id INT,
    IN order_total NUMERIC,
    OUT discount_percent NUMERIC
)
LANGUAGE plpgsql
AS $$
DECLARE
    customer_tier VARCHAR(20);
BEGIN
    -- Get customer tier
    SELECT tier INTO customer_tier
    FROM customers
    WHERE id = customer_id;
    
    -- Apply tier-based discount
    IF customer_tier = 'GOLD' THEN
        discount_percent := 0.15;
    ELSIF customer_tier = 'SILVER' THEN
        discount_percent := 0.10;
    ELSIF customer_tier = 'BRONZE' THEN
        discount_percent := 0.05;
    ELSE
        discount_percent := 0.00;
    END IF;
    
    -- Additional discount for large orders
    IF order_total > 1000 THEN
        discount_percent := discount_percent + 0.05;
    END IF;
END;
$$;
```

**CASE Statement:**

```sql
CREATE OR REPLACE PROCEDURE categorize_order(
    IN order_amount NUMERIC,
    OUT category VARCHAR(20)
)
LANGUAGE plpgsql
AS $$
BEGIN
    category := CASE
        WHEN order_amount < 50 THEN 'Small'
        WHEN order_amount BETWEEN 50 AND 200 THEN 'Medium'
        WHEN order_amount BETWEEN 200 AND 500 THEN 'Large'
        ELSE 'Extra Large'
    END;
END;
$$;
```

**LOOP:**

```sql
CREATE OR REPLACE PROCEDURE generate_dates(
    start_date DATE,
    end_date DATE
)
LANGUAGE plpgsql
AS $$
DECLARE
    current_date DATE := start_date;
BEGIN
    -- Create temporary table
    CREATE TEMP TABLE IF NOT EXISTS date_range (date_value DATE);
    
    LOOP
        INSERT INTO date_range VALUES (current_date);
        current_date := current_date + INTERVAL '1 day';
        
        EXIT WHEN current_date > end_date;
    END LOOP;
END;
$$;
```

**WHILE Loop:**

```sql
CREATE OR REPLACE PROCEDURE calculate_compound_interest(
    principal NUMERIC,
    rate NUMERIC,
    years INT,
    OUT final_amount NUMERIC
)
LANGUAGE plpgsql
AS $$
DECLARE
    year_count INT := 0;
BEGIN
    final_amount := principal;
    
    WHILE year_count < years LOOP
        final_amount := final_amount * (1 + rate);
        year_count := year_count + 1;
    END LOOP;
END;
$$;
```

**FOR Loop with Cursor:**

```sql
CREATE OR REPLACE PROCEDURE process_pending_orders()
LANGUAGE plpgsql
AS $$
DECLARE
    order_record RECORD;
BEGIN
    FOR order_record IN 
        SELECT order_id, customer_id, total 
        FROM orders 
        WHERE status = 'pending'
    LOOP
        -- Process each order
        UPDATE orders 
        SET status = 'processing',
            processed_at = NOW()
        WHERE order_id = order_record.order_id;
        
        -- Additional business logic
        INSERT INTO audit_log (order_id, action, timestamp)
        VALUES (order_record.order_id, 'PROCESSED', NOW());
    END LOOP;
END;
$$;
```

#### Error Handling in Stored Procedures

```sql
CREATE OR REPLACE PROCEDURE safe_update_inventory(
    p_product_id INT,
    p_quantity INT
)
LANGUAGE plpgsql
AS $$
DECLARE
    current_quantity INT;
BEGIN
    -- Start transaction
    BEGIN
        -- Lock row for update
        SELECT quantity INTO current_quantity
        FROM inventory
        WHERE product_id = p_product_id
        FOR UPDATE;
        
        -- Validate sufficient quantity
        IF current_quantity < p_quantity THEN
            RAISE EXCEPTION 'Insufficient inventory. Available: %, Requested: %', 
                current_quantity, p_quantity;
        END IF;
        
        -- Update inventory
        UPDATE inventory
        SET quantity = quantity - p_quantity,
            updated_at = NOW()
        WHERE product_id = p_product_id;
        
        -- Log the change
        INSERT INTO inventory_log (product_id, change_amount, timestamp)
        VALUES (p_product_id, -p_quantity, NOW());
        
    EXCEPTION
        WHEN OTHERS THEN
            -- Log error
            INSERT INTO error_log (error_message, error_time)
            VALUES (SQLERRM, NOW());
            
            -- Re-raise the exception
            RAISE;
    END;
END;
$$;
```

#### Complex Stored Procedure Example

```sql
CREATE OR REPLACE PROCEDURE process_monthly_billing()
LANGUAGE plpgsql
AS $$
DECLARE
    customer_record RECORD;
    invoice_id INT;
    total_amount NUMERIC;
    error_count INT := 0;
BEGIN
    -- Loop through active customers
    FOR customer_record IN 
        SELECT customer_id, email, billing_day
        FROM customers
        WHERE status = 'ACTIVE'
          AND billing_day = EXTRACT(DAY FROM CURRENT_DATE)
    LOOP
        BEGIN
            -- Calculate total charges for the month
            SELECT COALESCE(SUM(amount), 0)
            INTO total_amount
            FROM usage_charges
            WHERE customer_id = customer_record.customer_id
              AND charge_date >= DATE_TRUNC('month', CURRENT_DATE)
              AND charge_date < CURRENT_DATE
              AND invoiced = FALSE;
            
            -- Skip if no charges
            IF total_amount = 0 THEN
                CONTINUE;
            END IF;
            
            -- Create invoice
            INSERT INTO invoices (customer_id, amount, invoice_date, due_date, status)
            VALUES (
                customer_record.customer_id,
                total_amount,
                CURRENT_DATE,
                CURRENT_DATE + INTERVAL '30 days',
                'PENDING'
            )
            RETURNING invoice_id INTO invoice_id;
            
            -- Mark charges as invoiced
            UPDATE usage_charges
            SET invoiced = TRUE,
                invoice_id = invoice_id
            WHERE customer_id = customer_record.customer_id
              AND invoiced = FALSE;
            
            -- Send notification (would typically call external service)
            INSERT INTO notification_queue (customer_id, type, data)
            VALUES (
                customer_record.customer_id,
                'INVOICE_CREATED',
                json_build_object('invoice_id', invoice_id, 'amount', total_amount)
            );
            
            COMMIT;
            
        EXCEPTION
            WHEN OTHERS THEN
                -- Log error and continue with next customer
                INSERT INTO billing_errors (customer_id, error_message, error_time)
                VALUES (customer_record.customer_id, SQLERRM, NOW());
                
                error_count := error_count + 1;
                ROLLBACK;
        END;
    END LOOP;
    
    -- Summary log
    INSERT INTO batch_log (process_name, execution_time, error_count)
    VALUES ('monthly_billing', NOW(), error_count);
    
    RAISE NOTICE 'Billing process completed with % errors', error_count;
END;
$$;
```

---

### 8.3 User-Defined Functions

Functions are similar to procedures but always return a value and can be used in SQL expressions.

#### Scalar Functions

Return a single value.

```sql
-- PostgreSQL
CREATE OR REPLACE FUNCTION calculate_discount(
    price NUMERIC,
    discount_percent NUMERIC
)
RETURNS NUMERIC
LANGUAGE plpgsql
IMMUTABLE -- Function result depends only on inputs
AS $$
BEGIN
    RETURN price * (1 - discount_percent / 100);
END;
$$;

-- Use in query
SELECT 
    product_name,
    price,
    calculate_discount(price, 15) as discounted_price
FROM products;
```

**SQL Server:**

```sql
CREATE FUNCTION dbo.GetFullName(
    @FirstName NVARCHAR(50),
    @LastName NVARCHAR(50)
)
RETURNS NVARCHAR(101)
AS
BEGIN
    RETURN @FirstName + ' ' + @LastName;
END;
GO

-- Use in query
SELECT dbo.GetFullName(first_name, last_name) as full_name
FROM employees;
```

#### Table-Valued Functions

Return a result set (table).

```sql
-- PostgreSQL
CREATE OR REPLACE FUNCTION get_employee_hierarchy(root_employee_id INT)
RETURNS TABLE (
    employee_id INT,
    employee_name VARCHAR,
    level INT,
    path VARCHAR
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    WITH RECURSIVE hierarchy AS (
        SELECT 
            e.employee_id,
            e.first_name || ' ' || e.last_name as employee_name,
            1 as level,
            e.first_name || ' ' || e.last_name as path
        FROM employees e
        WHERE e.employee_id = root_employee_id
        
        UNION ALL
        
        SELECT 
            e.employee_id,
            e.first_name || ' ' || e.last_name,
            h.level + 1,
            h.path || ' -> ' || e.first_name || ' ' || e.last_name
        FROM employees e
        INNER JOIN hierarchy h ON e.manager_id = h.employee_id
    )
    SELECT * FROM hierarchy;
END;
$$;

-- Use like a table
SELECT * FROM get_employee_hierarchy(1);
```

**SQL Server Inline Table-Valued Function:**

```sql
CREATE FUNCTION dbo.GetOrdersByDateRange(
    @StartDate DATE,
    @EndDate DATE
)
RETURNS TABLE
AS
RETURN
(
    SELECT 
        order_id,
        customer_id,
        order_date,
        total
    FROM orders
    WHERE order_date BETWEEN @StartDate AND @EndDate
);
GO

-- Use in JOIN
SELECT c.customer_name, o.*
FROM customers c
INNER JOIN dbo.GetOrdersByDateRange('2024-01-01', '2024-12-31') o
    ON c.customer_id = o.customer_id;
```

#### Function Volatility Categories (PostgreSQL)

```sql
-- IMMUTABLE: Always returns same result for same inputs
CREATE FUNCTION add_numbers(a INT, b INT)
RETURNS INT
IMMUTABLE
LANGUAGE SQL
AS $$
    SELECT a + b;
$$;

-- STABLE: Returns same result within a transaction
CREATE FUNCTION get_exchange_rate(currency VARCHAR)
RETURNS NUMERIC
STABLE
LANGUAGE SQL
AS $$
    SELECT rate FROM exchange_rates 
    WHERE currency_code = currency;
$$;

-- VOLATILE: May return different results (default)
CREATE FUNCTION get_random_product()
RETURNS TABLE (product_id INT, name VARCHAR)
VOLATILE
LANGUAGE SQL
AS $$
    SELECT product_id, product_name 
    FROM products 
    ORDER BY RANDOM() 
    LIMIT 1;
$$;
```

> [!TIP]
> Marking functions as IMMUTABLE or STABLE when appropriate allows the query optimizer to cache results and improve performance.

#### Aggregate Functions

Create custom aggregation logic.

```sql
-- PostgreSQL: Create custom aggregate
CREATE AGGREGATE product_agg(NUMERIC) (
    SFUNC = numeric_mul,  -- State function
    STYPE = NUMERIC,      -- State type
    INITCOND = '1'        -- Initial condition
);

-- Use custom aggregate
SELECT product_agg(price) as price_product
FROM products;

-- More complex: Median aggregate
CREATE OR REPLACE FUNCTION array_median(NUMERIC[])
RETURNS NUMERIC
LANGUAGE SQL
AS $$
    SELECT AVG(val)
    FROM (
        SELECT val
        FROM unnest($1) val
        ORDER BY 1
        LIMIT 2 - MOD(array_upper($1, 1), 2)
        OFFSET CEIL(array_upper($1, 1) / 2.0) - 1
    ) sub;
$$;

CREATE AGGREGATE median(NUMERIC) (
    SFUNC = array_append,
    STYPE = NUMERIC[],
    FINALFUNC = array_median,
    INITCOND = '{}'
);

-- Use median aggregate
SELECT department_id, median(salary) as median_salary
FROM employees
GROUP BY department_id;
```

---

### 8.4 Triggers

Triggers automatically execute code in response to specific database events.

#### Types of Triggers

**Timing:**
- BEFORE: Execute before the operation
- AFTER: Execute after the operation
- INSTEAD OF: Replace the operation (views only)

**Events:**
- INSERT
- UPDATE
- DELETE
- TRUNCATE (table-level only)

**Granularity:**
- Row-level: Executes once per affected row
- Statement-level: Executes once per statement

#### Basic Trigger Syntax

**PostgreSQL:**

```sql
-- Create trigger function
CREATE OR REPLACE FUNCTION update_modified_timestamp()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$;

-- Create trigger
CREATE TRIGGER set_updated_at
BEFORE UPDATE ON products
FOR EACH ROW
EXECUTE FUNCTION update_modified_timestamp();

-- Test
UPDATE products SET price = 29.99 WHERE product_id = 1;
-- updated_at is automatically set
```

**MySQL:**

```sql
DELIMITER //

CREATE TRIGGER before_employee_update
BEFORE UPDATE ON employees
FOR EACH ROW
BEGIN
    SET NEW.updated_at = NOW();
    
    -- Validate salary increase
    IF NEW.salary > OLD.salary * 1.5 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Salary increase cannot exceed 50%';
    END IF;
END //

DELIMITER ;
```

**SQL Server:**

```sql
CREATE TRIGGER trg_OrderAudit
ON orders
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Log INSERT operations
    INSERT INTO order_audit (order_id, operation, timestamp)
    SELECT order_id, 'INSERT', GETDATE()
    FROM inserted
    WHERE NOT EXISTS (SELECT 1 FROM deleted WHERE deleted.order_id = inserted.order_id);
    
    -- Log UPDATE operations
    INSERT INTO order_audit (order_id, operation, timestamp)
    SELECT order_id, 'UPDATE', GETDATE()
    FROM inserted
    WHERE EXISTS (SELECT 1 FROM deleted WHERE deleted.order_id = inserted.order_id);
    
    -- Log DELETE operations
    INSERT INTO order_audit (order_id, operation, timestamp)
    SELECT order_id, 'DELETE', GETDATE()
    FROM deleted
    WHERE NOT EXISTS (SELECT 1 FROM inserted WHERE inserted.order_id = deleted.order_id);
END;
```

#### Common Trigger Use Cases

**1. Audit Trail:**

```sql
-- Create audit table
CREATE TABLE employee_audit (
    audit_id SERIAL PRIMARY KEY,
    employee_id INT,
    operation VARCHAR(10),
    old_values JSONB,
    new_values JSONB,
    changed_by VARCHAR(100),
    changed_at TIMESTAMP DEFAULT NOW()
);

-- Create audit trigger function
CREATE OR REPLACE FUNCTION audit_employee_changes()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        INSERT INTO employee_audit (employee_id, operation, new_values, changed_by)
        VALUES (NEW.employee_id, 'INSERT', to_jsonb(NEW), current_user);
        RETURN NEW;
    ELSIF TG_OP = 'UPDATE' THEN
        INSERT INTO employee_audit (employee_id, operation, old_values, new_values, changed_by)
        VALUES (NEW.employee_id, 'UPDATE', to_jsonb(OLD), to_jsonb(NEW), current_user);
        RETURN NEW;
    ELSIF TG_OP = 'DELETE' THEN
        INSERT INTO employee_audit (employee_id, operation, old_values, changed_by)
        VALUES (OLD.employee_id, 'DELETE', to_jsonb(OLD), current_user);
        RETURN OLD;
    END IF;
END;
$$;

-- Create trigger
CREATE TRIGGER employee_audit_trigger
AFTER INSERT OR UPDATE OR DELETE ON employees
FOR EACH ROW
EXECUTE FUNCTION audit_employee_changes();
```

**2. Enforce Business Rules:**

```sql
CREATE OR REPLACE FUNCTION enforce_credit_limit()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE
    customer_balance NUMERIC;
    customer_limit NUMERIC;
BEGIN
    -- Get customer's current balance and credit limit
    SELECT current_balance, credit_limit
    INTO customer_balance, customer_limit
    FROM customers
    WHERE customer_id = NEW.customer_id;
    
    -- Check if new order exceeds credit limit
    IF customer_balance + NEW.total > customer_limit THEN
        RAISE EXCEPTION 'Order exceeds credit limit. Balance: %, Limit: %, Order: %',
            customer_balance, customer_limit, NEW.total;
    END IF;
    
    RETURN NEW;
END;
$$;

CREATE TRIGGER check_credit_limit
BEFORE INSERT ON orders
FOR EACH ROW
EXECUTE FUNCTION enforce_credit_limit();
```

**3. Maintain Derived Data:**

```sql
-- Automatically update order total when items change
CREATE OR REPLACE FUNCTION update_order_total()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE
    new_total NUMERIC;
BEGIN
    -- Calculate new total
    SELECT COALESCE(SUM(quantity * unit_price), 0)
    INTO new_total
    FROM order_items
    WHERE order_id = COALESCE(NEW.order_id, OLD.order_id);
    
    -- Update order table
    UPDATE orders
    SET total = new_total,
        updated_at = NOW()
    WHERE order_id = COALESCE(NEW.order_id, OLD.order_id);
    
    RETURN COALESCE(NEW, OLD);
END;
$$;

CREATE TRIGGER maintain_order_total
AFTER INSERT OR UPDATE OR DELETE ON order_items
FOR EACH ROW
EXECUTE FUNCTION update_order_total();
```

**4. Cascade Soft Deletes:**

```sql
CREATE OR REPLACE FUNCTION cascade_soft_delete()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    -- When a customer is soft-deleted, soft-delete their orders
    UPDATE orders
    SET deleted_at = NOW()
    WHERE customer_id = NEW.customer_id
      AND deleted_at IS NULL;
    
    RETURN NEW;
END;
$$;

CREATE TRIGGER soft_delete_customer_orders
AFTER UPDATE OF deleted_at ON customers
FOR EACH ROW
WHEN (NEW.deleted_at IS NOT NULL AND OLD.deleted_at IS NULL)
EXECUTE FUNCTION cascade_soft_delete();
```

**5. Prevent Invalid Operations:**

```sql
CREATE OR REPLACE FUNCTION prevent_weekend_updates()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    IF EXTRACT(DOW FROM NOW()) IN (0, 6) THEN  -- 0 = Sunday, 6 = Saturday
        RAISE EXCEPTION 'Price updates are not allowed on weekends';
    END IF;
    RETURN NEW;
END;
$$;

CREATE TRIGGER no_weekend_price_updates
BEFORE UPDATE OF price ON products
FOR EACH ROW
EXECUTE FUNCTION prevent_weekend_updates();
```

**6. Auto-populate Fields:**

```sql
CREATE OR REPLACE FUNCTION set_order_number()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    -- Generate order number: YEAR-MONTH-SEQUENCE
    SELECT 
        TO_CHAR(NOW(), 'YYYY-MM') || '-' || 
        LPAD(COALESCE(MAX(order_sequence), 0)::TEXT, 6, '0')
    INTO NEW.order_number
    FROM orders
    WHERE DATE_TRUNC('month', created_at) = DATE_TRUNC('month', NOW());
    
    RETURN NEW;
END;
$$;

CREATE TRIGGER generate_order_number
BEFORE INSERT ON orders
FOR EACH ROW
EXECUTE FUNCTION set_order_number();
```

#### Trigger Variables (PostgreSQL)

**Special Variables Available in Triggers:**

```sql
CREATE OR REPLACE FUNCTION trigger_variables_example()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    RAISE NOTICE 'TG_NAME: %', TG_NAME;           -- Trigger name
    RAISE NOTICE 'TG_WHEN: %', TG_WHEN;           -- BEFORE or AFTER
    RAISE NOTICE 'TG_LEVEL: %', TG_LEVEL;         -- ROW or STATEMENT
    RAISE NOTICE 'TG_OP: %', TG_OP;               -- INSERT, UPDATE, DELETE, TRUNCATE
    RAISE NOTICE 'TG_TABLE_NAME: %', TG_TABLE_NAME; -- Table name
    RAISE NOTICE 'TG_TABLE_SCHEMA: %', TG_TABLE_SCHEMA; -- Schema name
    
    -- OLD: Row before operation (UPDATE/DELETE)
    -- NEW: Row after operation (INSERT/UPDATE)
    
    IF TG_OP = 'UPDATE' THEN
        RAISE NOTICE 'Old salary: %, New salary: %', OLD.salary, NEW.salary;
    END IF;
    
    RETURN NEW;
END;
$$;
```

#### Conditional Triggers

```sql
-- Only fire when specific column changes
CREATE TRIGGER update_salary_history
AFTER UPDATE OF salary ON employees
FOR EACH ROW
WHEN (OLD.salary IS DISTINCT FROM NEW.salary)
EXECUTE FUNCTION log_salary_change();

-- Only fire for certain rows
CREATE TRIGGER validate_premium_customer
BEFORE INSERT OR UPDATE ON orders
FOR EACH ROW
WHEN (NEW.total > 10000)
EXECUTE FUNCTION verify_premium_status();
```

#### Trigger Performance Considerations

> [!WARNING]
> **Triggers Can Impact Performance**
> - Execute on every affected row
> - Can cause cascading effects
> - Difficult to debug
> - Hidden business logic

**Best Practices:**

```sql
-- BAD: Trigger with complex query
CREATE OR REPLACE FUNCTION slow_trigger()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    -- Expensive query in trigger
    PERFORM * FROM large_table
    CROSS JOIN another_large_table
    WHERE complex_condition;
    
    RETURN NEW;
END;
$$;

-- GOOD: Keep triggers simple and fast
CREATE OR REPLACE FUNCTION fast_trigger()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    -- Simple, fast operation
    INSERT INTO audit_queue (table_name, row_id, operation)
    VALUES (TG_TABLE_NAME, NEW.id, TG_OP);
    
    RETURN NEW;
END;
$$;
```

**Trigger Debugging:**

```sql
-- Enable trigger logging
CREATE OR REPLACE FUNCTION debug_trigger()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    -- Log to file or table
    INSERT INTO trigger_debug_log (
        trigger_name,
        table_name,
        operation,
        row_data,
        timestamp
    )
    VALUES (
        TG_NAME,
        TG_TABLE_NAME,
        TG_OP,
        to_jsonb(NEW),
        NOW()
    );
    
    RETURN NEW;
END;
$$;
```

#### Managing Triggers

```sql
-- List all triggers on a table (PostgreSQL)
SELECT 
    trigger_name,
    event_manipulation,
    action_timing,
    action_statement
FROM information_schema.triggers
WHERE event_object_table = 'employees';

-- Disable trigger
ALTER TABLE employees DISABLE TRIGGER employee_audit_trigger;

-- Enable trigger
ALTER TABLE employees ENABLE TRIGGER employee_audit_trigger;

-- Drop trigger
DROP TRIGGER IF EXISTS employee_audit_trigger ON employees;

-- Drop trigger function
DROP FUNCTION IF EXISTS audit_employee_changes();
```

#### INSTEAD OF Triggers (For Views)

```sql
-- Create updateable view
CREATE VIEW active_employees AS
SELECT employee_id, first_name, last_name, salary
FROM employees
WHERE status = 'ACTIVE';

-- Create INSTEAD OF trigger
CREATE OR REPLACE FUNCTION update_active_employees_view()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    UPDATE employees
    SET first_name = NEW.first_name,
        last_name = NEW.last_name,
        salary = NEW.salary
    WHERE employee_id = NEW.employee_id
      AND status = 'ACTIVE';
    
    RETURN NEW;
END;
$$;

CREATE TRIGGER instead_of_update_active_employees
INSTEAD OF UPDATE ON active_employees
FOR EACH ROW
EXECUTE FUNCTION update_active_employees_view();

-- Now view is updateable
UPDATE active_employees SET salary = 75000 WHERE employee_id = 1;
```

---

## Summary and Quick Reference

### Performance Optimization Checklist

- [ ] Create indexes on frequently queried columns
- [ ] Use `EXPLAIN ANALYZE` to understand query performance
- [ ] Avoid `SELECT *`, specify needed columns
- [ ] Use appropriate JOIN types
- [ ] Limit result sets when possible
- [ ] Avoid functions on indexed columns in WHERE clauses
- [ ] Use batch operations for bulk updates/inserts
- [ ] Consider partitioning for very large tables
- [ ] Implement materialized views for complex aggregations
- [ ] Monitor and maintain database statistics
- [ ] Use connection pooling
- [ ] Cache frequently accessed data
- [ ] Use read replicas for read-heavy workloads

### Index Strategy

```sql
-- High-value indexing targets:
-- 1. Primary keys (automatic)
-- 2. Foreign keys
CREATE INDEX idx_orders_customer_id ON orders(customer_id);

-- 3. WHERE clause columns
CREATE INDEX idx_orders_status ON orders(status);

-- 4. JOIN columns
CREATE INDEX idx_order_items_order_id ON order_items(order_id);

-- 5. ORDER BY columns
CREATE INDEX idx_orders_created_at ON orders(created_at);

-- 6. Composite indexes for multi-column queries
CREATE INDEX idx_orders_customer_status ON orders(customer_id, status);

-- 7. Partial indexes for filtered queries
CREATE INDEX idx_active_orders ON orders(created_at) WHERE status = 'active';
```

### Query Patterns Reference

```sql
-- Top N per group
WITH ranked AS (
    SELECT *, ROW_NUMBER() OVER (PARTITION BY group_col ORDER BY value_col DESC) as rn
    FROM table_name
)
SELECT * FROM ranked WHERE rn <= 3;

-- Running totals
SELECT 
    date_col,
    amount,
    SUM(amount) OVER (ORDER BY date_col) as running_total
FROM transactions;

-- Gap detection
SELECT 
    id,
    LEAD(id) OVER (ORDER BY id) - id - 1 as gap_size
FROM sequences
WHERE LEAD(id) OVER (ORDER BY id) - id > 1;

-- Deduplication
DELETE FROM table_name
WHERE id NOT IN (
    SELECT MIN(id)
    FROM table_name
    GROUP BY unique_column
);

-- Upsert (INSERT or UPDATE)
INSERT INTO products (product_id, name, price)
VALUES (1, 'Widget', 19.99)
ON CONFLICT (product_id)
DO UPDATE SET name = EXCLUDED.name, price = EXCLUDED.price;
```

### Key Concepts Summary

| Concept | Use Case | Performance Impact |
|---------|----------|-------------------|
| **Indexes** | Speed up lookups | High (read), Negative (write) |
| **JOINs** | Combine related data | Medium to High |
| **Window Functions** | Analytics without grouping | Medium |
| **CTEs** | Readability, recursion | Low to Medium |
| **Partitioning** | Very large tables | High (with proper pruning) |
| **Materialized Views** | Pre-computed aggregates | High (read), Negative (write/refresh) |
| **Subqueries** | Nested logic | Variable (can be slow) |
| **EXISTS** | Check existence | Fast (short-circuits) |

---

## Conclusion

Mastering SQL is a journey from understanding basic SELECT statements to optimizing complex queries for production-scale systems. Key takeaways:

1. **Start with solid fundamentals** - Understand SELECT, WHERE, JOINs, and aggregations
2. **Learn advanced techniques** - Window functions, CTEs, and recursive queries unlock powerful analytics
3. **Optimize relentlessly** - Use indexes strategically, analyze query plans, and measure performance
4. **Design for scale** - Partition large tables, use materialized views, implement caching
5. **Follow best practices** - Write readable queries, use parameterized statements, maintain security

> [!TIP]
> The best way to master SQL is through practice. Work with real datasets, analyze query plans, and continuously refine your approach based on performance metrics.

Remember: **Premature optimization is the root of all evil**, but understanding these concepts allows you to make informed decisions when performance matters.

---

**Additional Resources:**
- Database documentation (PostgreSQL, MySQL, SQL Server, Oracle)
- Query optimization tools and profilers
- Database monitoring solutions
- SQL practice platforms and challenges

**Happy querying! 🚀**
