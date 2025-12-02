# SQL Challenges - Part 2: Intermediate Queries

**Difficulty Range:** 🟡 Medium  
**Total Challenges:** 15  
**Topics Covered:** JOINs (INNER, LEFT, RIGHT, FULL), GROUP BY, HAVING, Subqueries, CASE statements

---

## Challenge 1: INNER JOIN - Basic 🟡

**Difficulty:** Medium  
**Topic:** INNER JOIN fundamentals

### Problem
List all employees with their department names.

### Expected Output
```
employee_name      | job_title        | department_name
-------------------+------------------+------------------
John Smith         | CEO              | Executive
Sarah Johnson      | CFO              | Finance
...
```

### Solution
```sql
SELECT 
    e.first_name || ' ' || e.last_name AS employee_name,
    e.job_title,
    d.department_name
FROM employees e
INNER JOIN departments d ON e.department_id = d.department_id
WHERE e.status = 'ACTIVE'
ORDER BY d.department_name, e.last_name;
```

### Explanation
- `INNER JOIN` combines rows from both tables where the condition matches
- `ON e.department_id = d.department_id` specifies the join condition
- Table aliases (`e`, `d`) make queries shorter and more readable
- Only returns employees who have a matching department

### Key Concepts
- INNER JOIN syntax
- Table aliases
- Join conditions with ON
- Qualified column names (table.column)

### Variation - Show All Columns
```sql
SELECT 
    e.*,
    d.department_name,
    d.budget
FROM employees e
INNER JOIN departments d ON e.department_id = d.department_id;
```

---

## Challenge 2: Multiple JOINs 🟡

**Difficulty:** Medium  
**Topic:** Joining multiple tables

### Problem
Show employees with their department name, department location (city and country), and manager name.

### Expected Output
```
employee         | department    | location         | manager
-----------------+---------------+------------------+----------------
Emily Brown      | Sales         | New York, USA    | John Smith
...
```

### Solution
```sql
SELECT 
    e.first_name || ' ' || e.last_name AS employee,
    d.department_name AS department,
    l.city || ', ' || l.country AS location,
    m.first_name || ' ' || m.last_name AS manager
FROM employees e
INNER JOIN departments d ON e.department_id = d.department_id
INNER JOIN locations l ON d.location_id = l.location_id
LEFT JOIN employees m ON e.manager_id = m.employee_id
WHERE e.status = 'ACTIVE'
ORDER BY d.department_name, e.last_name;
```

### Explanation
- Multiple JOINs chain together
- `LEFT JOIN` for manager because CEO has no manager (NULL)
- Each JOIN adds information from another table
- Order of JOINs matters for logical flow

### Key Concepts
- Chaining multiple JOINs
- Mixing INNER and LEFT JOINs
- Self-join (employees to employees)

---

## Challenge 3: LEFT JOIN - Finding Missing Data 🟡

**Difficulty:** Medium  
**Topic:** LEFT JOIN with NULL checking

### Problem
Find all departments that currently have no employees assigned to them.

### Expected Output
```
department_id | department_name | employee_count
--------------+-----------------+----------------
... (any departments with 0 employees)
```

### Solution
```sql
SELECT 
    d.department_id,
    d.department_name,
    COUNT(e.employee_id) AS employee_count
FROM departments d
LEFT JOIN employees e ON d.department_id = e.department_id 
    AND e.status = 'ACTIVE'
GROUP BY d.department_id, d.department_name
HAVING COUNT(e.employee_id) = 0
ORDER BY d.department_name;
```

### Explanation
- `LEFT JOIN` keeps all departments, even without employees
- Filter in JOIN condition (`AND e.status = 'ACTIVE'`)
- `COUNT(e.employee_id)` counts non-NULL values
- `HAVING` filters grouped results

### Key Concepts
- LEFT JOIN to find missing relationships
- Filtering in JOIN vs WHERE
- GROUP BY with HAVING
- Counting NULLs

### Alternative Approach
```sql
-- Using WHERE IS NULL
SELECT 
    d.department_id,
    d.department_name
FROM departments d
LEFT JOIN employees e ON d.department_id = e.department_id 
    AND e.status = 'ACTIVE'
WHERE e.employee_id IS NULL;
```

---

## Challenge 4: GROUP BY - Basic Aggregation 🟡

**Difficulty:** Medium  
**Topic:** GROUP BY fundamentals

### Problem
Calculate the number of employees and average salary for each department.

### Expected Output
```
department_name    | employee_count | avg_salary
-------------------+----------------+------------
Sales              | 5              | 86000.00
Engineering        | 7              | 95000.00
...
```

### Solution
```sql
SELECT 
    d.department_name,
    COUNT(e.employee_id) AS employee_count,
    ROUND(AVG(e.salary), 2) AS avg_salary
FROM departments d
LEFT JOIN employees e ON d.department_id = e.department_id 
    AND e.status = 'ACTIVE'
GROUP BY d.department_id, d.department_name
ORDER BY employee_count DESC;
```

### Explanation
- `GROUP BY` groups rows by department
- Aggregate functions (COUNT, AVG) calculate per group
- All non-aggregated columns must be in GROUP BY
- LEFT JOIN ensures all departments appear

### Key Concepts
- GROUP BY clause
- Aggregate functions with grouping
- GROUP BY rules (all non-aggregated columns must be included)

### Common Mistake
```sql
-- ❌ WRONG - last_name not in GROUP BY
SELECT department_id, last_name, COUNT(*)
FROM employees
GROUP BY department_id;

-- ✅ CORRECT
SELECT department_id, COUNT(*) as employee_count
FROM employees
GROUP BY department_id;
```

---

## Challenge 5: HAVING Clause 🟡

**Difficulty:** Medium  
**Topic:** Filtering aggregated data

### Problem
Find departments with more than 3 employees and average salary greater than $80,000.

### Expected Output
Departments meeting both criteria.

### Solution
```sql
SELECT 
    d.department_name,
    COUNT(e.employee_id) AS employee_count,
    ROUND(AVG(e.salary), 2) AS avg_salary
FROM departments d
INNER JOIN employees e ON d.department_id = e.department_id
WHERE e.status = 'ACTIVE'
GROUP BY d.department_id, d.department_name
HAVING COUNT(e.employee_id) > 3 AND AVG(e.salary) > 80000
ORDER BY avg_salary DESC;
```

### Explanation
- `WHERE` filters rows before grouping
- `HAVING` filters groups after aggregation
- Can use aggregate functions in HAVING
- Both conditions in HAVING must be true

### Key Concepts
- HAVING vs WHERE
- Filtering aggregated results
- Order of execution: WHERE → GROUP BY → HAVING

### WHERE vs HAVING
```sql
-- WHERE: filters individual rows BEFORE grouping
WHERE e.status = 'ACTIVE'

-- HAVING: filters groups AFTER aggregation
HAVING COUNT(e.employee_id) > 3

-- Can't use aggregates in WHERE:
-- ❌ WHERE COUNT(*) > 3  -- ERROR!
-- ✅ HAVING COUNT(*) > 3  -- CORRECT
```

---

## Challenge 6: Orders with Customer Details 🟡

**Difficulty:** Medium  
**Topic:** JOIN with multiple tables

### Problem
List all orders with customer name, order date, status, and total amount. Include the count of items in each order.

### Expected Output
```
order_id | customer_name    | order_date | status    | total    | item_count
---------+------------------+------------+-----------+----------+------------
1        | Acme Corporation | 2024-01-15 | delivered | 2599.98  | 2
...
```

### Solution
```sql
SELECT 
    o.order_id,
    c.customer_name,
    o.order_date,
    o.status,
    o.total,
    COUNT(oi.order_item_id) AS item_count
FROM orders o
INNER JOIN customers c ON o.customer_id = c.customer_id
LEFT JOIN order_items oi ON o.order_id = oi.order_id
GROUP BY o.order_id, c.customer_name, o.order_date, o.status, o.total
ORDER BY o.order_date DESC;
```

### Explanation
- JOIN orders with customers for customer details
- LEFT JOIN order_items to count items (some orders might have no items)
- GROUP BY all non-aggregated columns
- COUNT gives number of items per order

### Key Concepts
- Multi-table JOINs
- Combining JOINs with GROUP BY
- Counting related records

---

## Challenge 7: Product Sales Analysis 🟡

**Difficulty:** Medium  
**Topic:** Aggregation with JOINs

### Problem
Find total quantity sold and revenue for each product. Include only products that have been sold at least once.

### Expected Output
```
product_name        | units_sold | total_revenue
--------------------+------------+---------------
Laptop Pro 15"      | 8          | 10399.92
...
```

### Solution
```sql
SELECT 
    p.product_name,
    SUM(oi.quantity) AS units_sold,
    SUM(oi.quantity * oi.unit_price) AS total_revenue
FROM products p
INNER JOIN order_items oi ON p.product_id = oi.product_id
GROUP BY p.product_id, p.product_name
ORDER BY total_revenue DESC;
```

### Explanation
- INNER JOIN ensures only sold products appear
- `SUM(quantity)` totals units sold
- `SUM(quantity * unit_price)` calculates revenue
- Calculated column in aggregate function

### Key Concepts
- Calculations within aggregates
- INNER JOIN for existence check
- Revenue calculation

### Including Unsold Products
```sql
SELECT 
    p.product_name,
    COALESCE(SUM(oi.quantity), 0) AS units_sold,
    COALESCE(SUM(oi.quantity * oi.unit_price), 0) AS total_revenue
FROM products p
LEFT JOIN order_items oi ON p.product_id = oi.product_id
GROUP BY p.product_id, p.product_name
ORDER BY total_revenue DESC;

-- COALESCE returns first non-NULL value
```

---

## Challenge 8: Simple Subquery in WHERE 🟡

**Difficulty:** Medium  
**Topic:** Subqueries in WHERE clause

### Problem
Find all employees who earn more than the average salary of all employees.

### Expected Output
Employees with above-average salaries.

### Solution
```sql
SELECT 
    first_name,
    last_name,
    job_title,
    salary,
    ROUND((SELECT AVG(salary) FROM employees), 2) AS company_avg
FROM employees
WHERE salary > (SELECT AVG(salary) FROM employees)
ORDER BY salary DESC;
```

### Explanation
- Subquery `(SELECT AVG(salary) FROM employees)` calculates average
- Executed first, then used in comparison
- Scalar subquery (returns single value)
- Can be used in SELECT and WHERE

### Key Concepts
- Scalar subqueries
- Subqueries in WHERE clause
- Using subquery results in comparisons

### Performance Note
```sql
-- More efficient with CTE (computed once)
WITH salary_stats AS (
    SELECT AVG(salary) AS avg_salary
    FROM employees
)
SELECT 
    e.first_name,
    e.last_name,
    e.salary,
    s.avg_salary
FROM employees e
CROSS JOIN salary_stats s
WHERE e.salary > s.avg_salary;
```

---

## Challenge 9: Subquery with IN 🟡

**Difficulty:** Medium  
**Topic:** Subqueries returning multiple rows

### Problem
Find all customers who have placed at least one order.

### Expected Output
```
customer_id | customer_name    | order_count
------------+------------------+-------------
1           | Acme Corporation | 3
...
```

### Solution
```sql
SELECT 
    c.customer_id,
    c.customer_name,
    (SELECT COUNT(*) 
     FROM orders o 
     WHERE o.customer_id = c.customer_id) AS order_count
FROM customers c
WHERE c.customer_id IN (
    SELECT DISTINCT customer_id 
    FROM orders
)
ORDER BY order_count DESC;
```

### Explanation
- Subquery in WHERE with IN finds customers with orders
- Subquery in SELECT (correlated) counts orders per customer
- `DISTINCT` eliminates duplicates in IN list

### Key Concepts
- IN with subqueries
- Correlated subqueries
- Multiple subqueries in one query

### Alternative - Using JOIN
```sql
SELECT 
    c.customer_id,
    c.customer_name,
    COUNT(o.order_id) AS order_count
FROM customers c
INNER JOIN orders o ON c.customer_id = o.customer_id
GROUP BY c.customer_id, c.customer_name
ORDER BY order_count DESC;
```

---

## Challenge 10: CASE Statement - Simple 🟡

**Difficulty:** Medium  
**Topic:** Conditional logic with CASE

### Problem
Categorize employees by salary range: 'Entry' (<$70k), 'Mid' ($70k-$120k), 'Senior' (>$120k).

### Expected Output
```
employee_name   | salary    | salary_category
----------------+-----------+-----------------
John Smith      | 250000.00 | Senior
...
```

### Solution
```sql
SELECT 
    first_name || ' ' || last_name AS employee_name,
    salary,
    CASE 
        WHEN salary < 70000 THEN 'Entry'
        WHEN salary BETWEEN 70000 AND 120000 THEN 'Mid'
        WHEN salary > 120000 THEN 'Senior'
        ELSE 'Unknown'
    END AS salary_category
FROM employees
WHERE status = 'ACTIVE'
ORDER BY salary DESC;
```

### Explanation
- `CASE` evaluates conditions top to bottom
- First matching condition wins
- `ELSE` handles unmatched cases (optional but recommended)
- `END` closes the CASE statement

### Key Concepts
- CASE statement syntax
- Conditional logic in SQL
- Creating categorized columns

### Counting by Category
```sql
SELECT 
    CASE 
        WHEN salary < 70000 THEN 'Entry'
        WHEN salary BETWEEN 70000 AND 120000 THEN 'Mid'
        ELSE 'Senior'
    END AS salary_category,
    COUNT(*) AS employee_count,
    ROUND(AVG(salary), 2) AS avg_salary
FROM employees
WHERE status = 'ACTIVE'
GROUP BY salary_category
ORDER BY avg_salary;
```

---

## Challenge 11: CASE in Aggregation 🟡

**Difficulty:** Medium  
**Topic:** CASE with aggregate functions

### Problem
Create a summary showing counts of orders by status: pending, processing, shipped, and delivered.

### Expected Output
```
total_orders | pending | processing | shipped | delivered
-------------+---------+------------+---------+-----------
20           | 4       | 3          | 3       | 10
```

### Solution
```sql
SELECT 
    COUNT(*) AS total_orders,
    COUNT(CASE WHEN status = 'pending' THEN 1 END) AS pending,
    COUNT(CASE WHEN status = 'processing' THEN 1 END) AS processing,
    COUNT(CASE WHEN status = 'shipped' THEN 1 END) AS shipped,
    COUNT(CASE WHEN status = 'delivered' THEN 1 END) AS delivered
FROM orders;
```

### Explanation
- CASE inside COUNT for conditional counting
- Returns 1 when condition is true, NULL otherwise
- COUNT ignores NULL values
- Creates pivot-like summary

### Key Concepts
- Conditional aggregation
- CASE within aggregate functions
- Pivot table technique

### Alternative - Using SUM
```sql
SELECT 
    COUNT(*) AS total_orders,
    SUM(CASE WHEN status = 'pending' THEN 1 ELSE 0 END) AS pending,
    SUM(CASE WHEN status = 'processing' THEN 1 ELSE 0 END) AS processing,
    SUM(CASE WHEN status = 'shipped' THEN 1 ELSE 0 END) AS shipped,
    SUM(CASE WHEN status = 'delivered' THEN 1 ELSE 0 END) AS delivered
FROM orders;
```

---

## Challenge 12: Self-Join for Hierarchy 🟡

**Difficulty:** Medium  
**Topic:** Self-joins

### Problem
List all employees with their direct reports count. Include employees with no reports.

### Expected Output
```
manager_name     | job_title        | direct_reports
-----------------+------------------+----------------
John Smith       | CEO              | 9
Emily Brown      | VP Sales         | 3
...
```

### Solution
```sql
SELECT 
    m.first_name || ' ' || m.last_name AS manager_name,
    m.job_title,
    COUNT(e.employee_id) AS direct_reports
FROM employees m
LEFT JOIN employees e ON m.employee_id = e.manager_id 
    AND e.status = 'ACTIVE'
WHERE m.status = 'ACTIVE'
GROUP BY m.employee_id, m.first_name, m.last_name, m.job_title
ORDER BY direct_reports DESC;
```

### Explanation
- Table joined to itself with different aliases
- `m` for managers, `e` for employees
- LEFT JOIN to include managers with no reports
- COUNT counts direct reports

### Key Concepts
- Self-join technique
- Hierarchical data queries
- Table aliases are required for self-joins

---

## Challenge 13: Customer Tier Analysis 🟡

**Difficulty:** Medium  
**Topic:** GROUP BY with multiple dimensions

### Problem
Show customer statistics by tier: count, total balance, average balance, and total credit limit.

### Expected Output
```
tier   | customer_count | total_balance | avg_balance | total_credit_limit
-------+----------------+---------------+-------------+--------------------
GOLD   | 6              | 120000.00     | 20000.00    | 520000.00
...
```

### Solution
```sql
SELECT 
    tier,
    COUNT(*) AS customer_count,
    SUM(current_balance) AS total_balance,
    ROUND(AVG(current_balance), 2) AS avg_balance,
    SUM(credit_limit) AS total_credit_limit
FROM customers
WHERE status = 'ACTIVE'
GROUP BY tier
ORDER BY 
    CASE tier
        WHEN 'GOLD' THEN 1
        WHEN 'SILVER' THEN 2
        WHEN 'BRONZE' THEN 3
    END;
```

### Explanation
- Multiple aggregates on same GROUP BY
- Custom ORDER BY using CASE for tier ranking
- Financial metrics aggregation

### Key Concepts
- Multiple aggregates in one query
- CASE in ORDER BY
- Financial data aggregation

---

## Challenge 14: Top Customers by Order Value 🟡

**Difficulty:** Medium  
**Topic:** JOINs, aggregation, and ranking

### Problem
Find top 5 customers by total order value. Show customer name, tier, number of orders, and total spent.

### Expected Output
```
customer_name          | tier   | order_count | total_spent
-----------------------+--------+-------------+-------------
Big Enterprise         | GOLD   | 1           | 7899.90
...
```

### Solution
```sql
SELECT 
    c.customer_name,
    c.tier,
    COUNT(o.order_id) AS order_count,
    COALESCE(SUM(o.total), 0) AS total_spent
FROM customers c
LEFT JOIN orders o ON c.customer_id = o.customer_id
GROUP BY c.customer_id, c.customer_name, c.tier
ORDER BY total_spent DESC
LIMIT 5;
```

### Explanation
- LEFT JOIN to include customers with no orders
- COALESCE handles NULL for customers without orders
- GROUP BY customer aggregates all their orders
- LIMIT restricts to top 5

### Key Concepts
- Top-N queries
- COALESCE for NULL handling
- Customer analytics

---

## Challenge 15: Monthly Order Trends 🟡

**Difficulty:** Medium  
**Topic:** Date functions with GROUP BY

### Problem
Show order counts and total revenue by month for 2024.

### Expected Output
```
month      | order_count | monthly_revenue
-----------+-------------+-----------------
2024-01-01 | 3           | 5029.94
2024-02-01 | 4           | 4389.89
...
```

### Solution
```sql
SELECT 
    DATE_TRUNC('month', order_date) AS month,
    COUNT(*) AS order_count,
    SUM(total) AS monthly_revenue
FROM orders
WHERE EXTRACT(YEAR FROM order_date) = 2024
GROUP BY DATE_TRUNC('month', order_date)
ORDER BY month;
```

### Explanation
- `DATE_TRUNC('month', date)` truncates to first day of month
- Groups all orders in same month together
- `EXTRACT(YEAR FROM date)` filters to 2024
- Useful for time-series analysis

### Key Concepts
- Date truncation functions
- Date extraction
- Time-series aggregation

---

## 📚 Summary - Part 2: Intermediate Queries

### What You've Learned

✅ **JOIN Operations**
- INNER JOIN, LEFT JOIN
- Multiple table JOINs
- Self-joins

✅ **GROUP BY & Aggregation**
- GROUP BY with aggregates
- HAVING clause
- WHERE vs HAVING

✅ **Subqueries**
- Scalar subqueries
- Subqueries with IN
- Correlated subqueries

✅ **CASE Statements**
- Categorization
- Conditional aggregation
- Pivot techniques

### Key Takeaways

1. **INNER vs LEFT JOIN**: Use INNER when you need matching rows, LEFT when you need all from one table
2. **GROUP BY rule**: All non-aggregated columns must be in GROUP BY
3. **WHERE vs HAVING**: WHERE filters rows, HAVING filters groups
4. **Subqueries**: Often can be replaced with JOIN for better performance
5. **CASE is powerful**: Use for categorization and conditional logic

**Continue to:** [Part 3: Advanced Queries](file:///c:/Users/phusukale/Downloads/Docs/Repo/SQL_Challanges/sql-challenges-part3-advanced.md)

---

## 🎯 Bonus Practice Challenges

1. Find employees earning more than their department's average
2. List products never ordered
3. Calculate year-over-year sales growth
4. Find customers with orders in more than 3 different months
5. Show product categories with highest average price

**Keep practicing! 🚀**
