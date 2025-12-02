# SQL Practice Guide

## Getting Started

This guide helps you practice all the concepts from the comprehensive SQL guide using the provided database.

## Database Setup

### Option 1: PostgreSQL (Recommended)

```bash
# Create database
createdb company_db

# Import the schema and data
psql -d company_db -f sql-practice-database.sql
```

### Option 2: MySQL

```bash
# Create database
mysql -u root -p -e "CREATE DATABASE company_db;"

# Import (after adjusting syntax if needed)
mysql -u root -p company_db < sql-practice-database.sql
```

### Option 3: SQLite

```bash
# Create and import
sqlite3 company_db.db < sql-practice-database.sql
```

---

## Database Schema Overview

### Core Tables

| Table | Records | Purpose |
|-------|---------|---------|
| `employees` | 37 | Employee data with hierarchy |
| `departments` | 10 | Department information |
| `customers` | 15 | Customer accounts |
| `products` | 25 | Product catalog |
| `orders` | 20 | Customer orders |
| `order_items` | 45 | Line items for orders |
| `locations` | 8 | Office locations |
| `accounts` | 10 | Financial accounts |
| `inventory` | 25 | Stock levels |
| `sales` | 18 | Sales analytics data |

### Supporting Tables

- **Audit Tables**: `employee_audit`, `order_audit`, `audit_log`
- **Logging Tables**: `transaction_log`, `inventory_log`, `error_log`
- **Specialized**: `bill_of_materials`, `flights`, `exchange_rates`

---

## Practice Exercises by Topic

### 1. Basic SELECT Queries

```sql
-- Exercise 1.1: Select all employees
SELECT * FROM employees;

-- Exercise 1.2: Select specific columns
SELECT first_name, last_name, salary FROM employees;

-- Exercise 1.3: Select with WHERE clause
SELECT * FROM employees WHERE salary > 100000;

-- Exercise 1.4: Using multiple conditions
SELECT * FROM employees 
WHERE department_id = 4 AND salary > 80000;

-- Exercise 1.5: Pattern matching
SELECT * FROM customers WHERE email LIKE '%@gmail.com';

-- Exercise 1.6: Sorting results
SELECT first_name, last_name, salary 
FROM employees 
ORDER BY salary DESC 
LIMIT 10;
```

### 2. Aggregate Functions

```sql
-- Exercise 2.1: Count employees
SELECT COUNT(*) as total_employees FROM employees;

-- Exercise 2.2: Average salary
SELECT AVG(salary) as avg_salary FROM employees;

-- Exercise 2.3: Group by department
SELECT 
    department_id,
    COUNT(*) as employee_count,
    AVG(salary) as avg_salary,
    MAX(salary) as max_salary
FROM employees
GROUP BY department_id;

-- Exercise 2.4: Having clause
SELECT 
    department_id,
    COUNT(*) as employee_count
FROM employees
GROUP BY department_id
HAVING COUNT(*) > 3;
```

### 3. JOINs Practice

```sql
-- Exercise 3.1: INNER JOIN - Employees with departments
SELECT 
    e.first_name,
    e.last_name,
    d.department_name
FROM employees e
INNER JOIN departments d ON e.department_id = d.department_id;

-- Exercise 3.2: LEFT JOIN - All departments with employee count
SELECT 
    d.department_name,
    COUNT(e.employee_id) as employee_count
FROM departments d
LEFT JOIN employees e ON d.department_id = e.department_id
GROUP BY d.department_name;

-- Exercise 3.3: Multiple JOINs - Full employee context
SELECT 
    e.first_name || ' ' || e.last_name as employee,
    e.job_title,
    d.department_name,
    l.city,
    l.country
FROM employees e
INNER JOIN departments d ON e.department_id = d.department_id
INNER JOIN locations l ON d.location_id = l.location_id;

-- Exercise 3.4: SELF JOIN - Employees and their managers
SELECT 
    e.first_name || ' ' || e.last_name as employee,
    m.first_name || ' ' || m.last_name as manager,
    e.job_title
FROM employees e
LEFT JOIN employees m ON e.manager_id = m.employee_id;
```

### 4. Subqueries

```sql
-- Exercise 4.1: Simple subquery - Above average salary
SELECT first_name, last_name, salary
FROM employees
WHERE salary > (SELECT AVG(salary) FROM employees);

-- Exercise 4.2: Correlated subquery - Above department average
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

-- Exercise 4.3: EXISTS - Departments with employees
SELECT department_name
FROM departments d
WHERE EXISTS (
    SELECT 1 
    FROM employees e 
    WHERE e.department_id = d.department_id
);

-- Exercise 4.4: IN subquery - Customers who placed orders
SELECT customer_name
FROM customers
WHERE customer_id IN (
    SELECT DISTINCT customer_id FROM orders
);
```

### 5. Common Table Expressions (CTEs)

```sql
-- Exercise 5.1: Simple CTE - Department averages
WITH dept_stats AS (
    SELECT 
        department_id,
        AVG(salary) as avg_salary,
        COUNT(*) as employee_count
    FROM employees
    GROUP BY department_id
)
SELECT 
    d.department_name,
    ds.avg_salary,
    ds.employee_count
FROM departments d
JOIN dept_stats ds ON d.department_id = ds.department_id
WHERE ds.avg_salary > 80000;

-- Exercise 5.2: Multiple CTEs
WITH 
high_earners AS (
    SELECT * FROM employees WHERE salary > 100000
),
dept_sizes AS (
    SELECT department_id, COUNT(*) as size
    FROM employees
    GROUP BY department_id
)
SELECT 
    he.first_name,
    he.last_name,
    he.salary,
    ds.size as dept_size
FROM high_earners he
JOIN dept_sizes ds ON he.department_id = ds.department_id;

-- Exercise 5.3: Recursive CTE - Employee hierarchy
WITH RECURSIVE emp_hierarchy AS (
    -- Anchor: Top-level employees
    SELECT 
        employee_id,
        first_name,
        last_name,
        manager_id,
        1 as level,
        first_name || ' ' || last_name as path
    FROM employees
    WHERE manager_id IS NULL
    
    UNION ALL
    
    -- Recursive: Employees reporting to current level
    SELECT 
        e.employee_id,
        e.first_name,
        e.last_name,
        e.manager_id,
        eh.level + 1,
        eh.path || ' -> ' || e.first_name || ' ' || e.last_name
    FROM employees e
    JOIN emp_hierarchy eh ON e.manager_id = eh.employee_id
)
SELECT * FROM emp_hierarchy ORDER BY level, path;
```

### 6. Window Functions

```sql
-- Exercise 6.1: ROW_NUMBER - Rank employees by salary
SELECT 
    first_name,
    last_name,
    department_id,
    salary,
    ROW_NUMBER() OVER (ORDER BY salary DESC) as overall_rank,
    ROW_NUMBER() OVER (PARTITION BY department_id ORDER BY salary DESC) as dept_rank
FROM employees;

-- Exercise 6.2: RANK and DENSE_RANK
SELECT 
    first_name,
    last_name,
    salary,
    RANK() OVER (ORDER BY salary DESC) as rank,
    DENSE_RANK() OVER (ORDER BY salary DESC) as dense_rank
FROM employees;

-- Exercise 6.3: LAG and LEAD - Compare with previous/next
SELECT 
    order_date,
    total,
    LAG(total) OVER (ORDER BY order_date) as previous_order,
    LEAD(total) OVER (ORDER BY order_date) as next_order,
    total - LAG(total) OVER (ORDER BY order_date) as change_from_prev
FROM orders;

-- Exercise 6.4: Running totals
SELECT 
    order_date,
    total,
    SUM(total) OVER (ORDER BY order_date) as running_total,
    AVG(total) OVER (ORDER BY order_date ROWS BETWEEN 2 PRECEDING AND CURRENT ROW) as moving_avg_3
FROM orders;

-- Exercise 6.5: Top N per group
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
SELECT * FROM ranked_employees WHERE rank <= 3;
```

### 7. Advanced Analytics

```sql
-- Exercise 7.1: PIVOT - Sales by region and quarter
SELECT 
    region,
    SUM(CASE WHEN quarter = 1 THEN sale_amount ELSE 0 END) as Q1,
    SUM(CASE WHEN quarter = 2 THEN sale_amount ELSE 0 END) as Q2,
    SUM(CASE WHEN quarter = 3 THEN sale_amount ELSE 0 END) as Q3,
    SUM(CASE WHEN quarter = 4 THEN sale_amount ELSE 0 END) as Q4
FROM sales
GROUP BY region;

-- Exercise 7.2: ROLLUP - Hierarchical totals
SELECT 
    region,
    product_category,
    SUM(sale_amount) as total_sales,
    GROUPING(region) as region_total,
    GROUPING(product_category) as category_total
FROM sales
GROUP BY ROLLUP (region, product_category)
ORDER BY region, product_category;

-- Exercise 7.3: CUBE - All combinations
SELECT 
    region,
    customer_segment,
    SUM(sale_amount) as total_sales
FROM sales
GROUP BY CUBE (region, customer_segment);
```

### 8. Complex Queries

```sql
-- Exercise 8.1: Customer lifetime value
SELECT 
    c.customer_name,
    COUNT(o.order_id) as total_orders,
    SUM(o.total) as lifetime_value,
    AVG(o.total) as avg_order_value,
    MAX(o.order_date) as last_order_date
FROM customers c
LEFT JOIN orders o ON c.customer_id = o.customer_id
GROUP BY c.customer_id, c.customer_name
ORDER BY lifetime_value DESC;

-- Exercise 8.2: Product performance analysis
SELECT 
    p.product_name,
    p.category_id,
    COUNT(DISTINCT oi.order_id) as orders_count,
    SUM(oi.quantity) as units_sold,
    SUM(oi.quantity * oi.unit_price) as revenue,
    AVG(oi.unit_price) as avg_price,
    p.price as current_price
FROM products p
LEFT JOIN order_items oi ON p.product_id = oi.product_id
GROUP BY p.product_id, p.product_name, p.category_id, p.price
ORDER BY revenue DESC;

-- Exercise 8.3: Employee compensation analysis
SELECT 
    d.department_name,
    COUNT(e.employee_id) as employee_count,
    MIN(e.salary) as min_salary,
    PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY e.salary) as q1_salary,
    PERCENTILE_CONT(0.50) WITHIN GROUP (ORDER BY e.salary) as median_salary,
    PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY e.salary) as q3_salary,
    MAX(e.salary) as max_salary,
    AVG(e.salary) as avg_salary
FROM departments d
LEFT JOIN employees e ON d.department_id = e.department_id
GROUP BY d.department_name
ORDER BY avg_salary DESC;
```

### 9. Transaction Practice

```sql
-- Exercise 9.1: Simple transaction
BEGIN;
    UPDATE accounts SET balance = balance - 100 WHERE account_id = 1;
    UPDATE accounts SET balance = balance + 100 WHERE account_id = 2;
COMMIT;

-- Exercise 9.2: Transaction with rollback
BEGIN;
    UPDATE inventory SET quantity = quantity - 10 WHERE product_id = 1;
    -- Check if sufficient quantity
    SELECT quantity FROM inventory WHERE product_id = 1;
    -- If insufficient, rollback
    ROLLBACK;

-- Exercise 9.3: Savepoints
BEGIN;
    INSERT INTO orders (customer_id, order_date, status) 
    VALUES (1, CURRENT_DATE, 'pending');
    
    SAVEPOINT before_items;
    
    INSERT INTO order_items (order_id, product_id, quantity, unit_price)
    VALUES (100, 1, 5, 1299.99);
    
    -- If something wrong, rollback to savepoint
    ROLLBACK TO SAVEPOINT before_items;
    
    -- Try different items
    INSERT INTO order_items (order_id, product_id, quantity, unit_price)
    VALUES (100, 2, 3, 1899.99);
    
COMMIT;
```

### 10. Performance Analysis

```sql
-- Exercise 10.1: Explain plan
EXPLAIN ANALYZE
SELECT e.first_name, e.last_name, d.department_name
FROM employees e
JOIN departments d ON e.department_id = d.department_id
WHERE e.salary > 100000;

-- Exercise 10.2: Index usage
EXPLAIN ANALYZE
SELECT * FROM employees WHERE email = 'john.smith@company.com';

-- Exercise 10.3: Compare queries
-- Inefficient
EXPLAIN ANALYZE
SELECT * FROM employees WHERE YEAR(hire_date) = 2024;

-- Efficient
EXPLAIN ANALYZE
SELECT * FROM employees 
WHERE hire_date >= '2024-01-01' AND hire_date < '2025-01-01';
```

---

## Challenge Exercises

### Challenge 1: Revenue Analysis Dashboard

Create a comprehensive revenue analysis showing:
- Monthly revenue trends
- Top 10 products by revenue
- Top 5 customers by lifetime value
- Sales performance by employee
- Category breakdown

### Challenge 2: Employee Analytics

Build a complete employee analytics report:
- Department hierarchy with headcount
- Salary distribution by department
- Manager span of control
- Tenure analysis
- Compensation percentiles

### Challenge 3: Inventory Management

Create inventory alerts and reports:
- Products below reorder level
- Stock value by warehouse
- Fast-moving vs slow-moving products
- Stock turnover rate
- Reorder recommendations

### Challenge 4: Customer Segmentation

Segment customers based on:
- Purchase frequency
- Average order value
- Recency of last purchase
- Product preferences
- Credit utilization

---

## Practice Stored Procedures

```sql
-- Exercise: Create a transfer funds procedure
CREATE OR REPLACE PROCEDURE transfer_money(
    from_account_id INT,
    to_account_id INT,
    amount NUMERIC
)
LANGUAGE plpgsql
AS $$
BEGIN
    -- Your implementation here
    -- Check balance
    -- Debit from account
    -- Credit to account
    -- Log transaction
END;
$$;
```

## Practice Triggers

```sql
-- Exercise: Create auto-update timestamp trigger
CREATE OR REPLACE FUNCTION update_timestamp()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER products_timestamp
BEFORE UPDATE ON products
FOR EACH ROW
EXECUTE FUNCTION update_timestamp();
```

## Practice Functions

```sql
-- Exercise: Create a function to calculate order total
CREATE OR REPLACE FUNCTION calculate_order_total(p_order_id INT)
RETURNS NUMERIC AS $$
DECLARE
    total NUMERIC;
BEGIN
    SELECT SUM(quantity * unit_price)
    INTO total
    FROM order_items
    WHERE order_id = p_order_id;
    
    RETURN COALESCE(total, 0);
END;
$$ LANGUAGE plpgsql;

-- Test it
SELECT calculate_order_total(1);
```

---

## Tips for Effective Practice

1. **Start Simple**: Begin with basic SELECT queries, then progress to complex ones
2. **Experiment**: Modify the sample queries to see different results
3. **Use EXPLAIN**: Analyze query performance frequently
4. **Break Problems Down**: For complex queries, build them step by step
5. **Check Results**: Verify your query results make sense
6. **Practice Transactions**: Understand ACID properties through practice
7. **Write Procedures**: Implement business logic in stored procedures
8. **Create Triggers**: Automate tasks with triggers
9. **Optimize**: Try to improve query performance
10. **Document**: Comment your complex queries

---

## Next Steps

1. Complete all exercises in order
2. Attempt the challenge exercises
3. Create your own practice scenarios
4. Build a complete application using this database
5. Experiment with different database systems
6. Study query execution plans
7. Practice database design principles

**Happy Learning! 🚀**
