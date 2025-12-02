# SQL Challenges - Part 5: Database Design & Administration

**Difficulty Range:** 🔴 Hard  
**Total Challenges:** 10  
**Topics Covered:** Table Creation, Constraints, Indexes, Views, Schema Design, Performance

**Database:** All challenges use `sql-practice-database.sql` (company_db)

---

## Challenge 1: CREATE TABLE with Constraints 🔴

**Difficulty:** Hard  
**Topic:** Table creation with comprehensive constraints

### Problem
Create a new table `product_reviews` with proper constraints for storing customer reviews.

### Solution
```sql
CREATE TABLE product_reviews (
    review_id SERIAL PRIMARY KEY,
    reviewer_id INT NOT NULL,
    product_id INT NOT NULL,
    rating INT NOT NULL CHECK (rating BETWEEN 1 AND 5),
    review_text TEXT,
    review_date DATE NOT NULL DEFAULT CURRENT_DATE,
    helpful_count INT NOT NULL DEFAULT 0 CHECK (helpful_count >= 0),
    verified_purchase BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT NOW(),
    
    -- Foreign Keys
    CONSTRAINT fk_reviewer FOREIGN KEY (reviewer_id) 
        REFERENCES customers(customer_id) ON DELETE CASCADE,
    CONSTRAINT fk_product FOREIGN KEY (product_id) 
        REFERENCES products(product_id) ON DELETE CASCADE,
    
    -- Unique Constraint
    CONSTRAINT unique_customer_product UNIQUE (reviewer_id, product_id)
);

-- Add indexes
CREATE INDEX idx_reviews_product ON product_reviews(product_id);
CREATE INDEX idx_reviews_rating ON product_reviews(rating);
```

### Key Concepts
- Comprehensive table design, Constraint types (PK, FK, UNIQUE, CHECK, NOT NULL), Default values, Index creation

---

## Challenge 2: ALTER TABLE Operations 🔴

**Difficulty:** Hard  
**Topic:** Modifying existing tables

### Problem
Modify the products table to add: SKU column (unique, not null), check constraint that cost < price, and composite index on (category_id, price).

### Solution
```sql
-- Add new column
ALTER TABLE products ADD COLUMN sku VARCHAR(50);

-- Populate existing rows
UPDATE products SET sku = 'SKU-' || LPAD(product_id::TEXT, 6, '0');

-- Make it NOT NULL and UNIQUE
ALTER TABLE products
ALTER COLUMN sku SET NOT NULL,
ADD CONSTRAINT unique_sku UNIQUE (sku);

-- Add CHECK constraint
ALTER TABLE products
ADD CONSTRAINT check_cost_vs_price CHECK (cost < price);

-- Add composite index
CREATE INDEX idx_products_category_price 
ON products(category_id, price DESC);
```

### Key Concepts
- Schema evolution, Adding constraints to existing tables, Composite indexes

---

## Challenge 3: CREATE INDEX for Performance 🔴

**Difficulty:** Hard  
**Topic:** Index types and optimization

### Problem
Create appropriate indexes for common queries.

### Solution
```sql
-- Composite index with partial filter
CREATE INDEX idx_emp_dept_salary 
ON employees(department_id, salary)
WHERE status = 'ACTIVE';

-- Case-insensitive search
CREATE INDEX idx_customers_email_lower 
ON customers(LOWER(email));

-- Covering index (PostgreSQL 11+)
CREATE INDEX idx_orders_date_status 
ON orders(order_date DESC, status)
INCLUDE (total);

-- Pattern matching index
CREATE INDEX idx_products_name_pattern 
ON products(product_name text_pattern_ops);

-- Full-text search index
CREATE INDEX idx_products_name_fts 
ON products USING GIN(to_tsvector('english', product_name));
```

### Key Concepts
- Index types (B-tree, GIN, partial, expression), Covering indexes, Full-text search, Query optimization

---

## Challenge 4: CREATE VIEW 🔴

**Difficulty:** Hard  
**Topic:** Views for data abstraction

### Problem
Create views for: employee directory, product sales summary, and customer account balance.

### Solution
```sql
-- Employee Directory View
CREATE OR REPLACE VIEW v_employee_directory AS
SELECT 
    e.employee_id,
    e.first_name || ' ' || e.last_name AS full_name,
    e.email,
    e.job_title,
    d.department_name,
    l.city || ', ' || l.country AS location,
    m.first_name || ' ' || m.last_name AS manager_name
FROM employees e
INNER JOIN departments d ON e.department_id = d.department_id
INNER JOIN locations l ON d.location_id = l.location_id
LEFT JOIN employees m ON e.manager_id = m.employee_id
WHERE e.status = 'ACTIVE';

-- Product Sales Summary View
CREATE OR REPLACE VIEW v_product_sales_summary AS
SELECT 
    p.product_id,
    p.product_name,
    p.price AS current_price,
    COALESCE(SUM(oi.quantity), 0) AS total_units_sold,
    COALESCE(SUM(oi.quantity * oi.unit_price), 0) AS total_revenue,
    COUNT(DISTINCT oi.order_id) AS order_count
FROM products p
LEFT JOIN order_items oi ON p.product_id = oi.product_id
GROUP BY p.product_id, p.product_name, p.price;

-- Customer Account Summary View
CREATE OR REPLACE VIEW v_customer_account_summary AS
SELECT 
    c.customer_id,
    c.customer_name,
    c.tier,
    COUNT(o.order_id) AS total_orders,
    COALESCE(SUM(o.total), 0) AS lifetime_value,
    MAX(o.order_date) AS last_order_date
FROM customers c
LEFT JOIN orders o ON c.customer_id = o.customer_id
WHERE c.status = 'ACTIVE'
GROUP BY c.customer_id, c.customer_name, c.tier;
```

### Key Concepts
- View creation and usage, Data abstraction, Query reusability

---

## Challenge 5: Materialized View 🔴

**Difficulty:** Hard  
**Topic:** Materialized views for performance

### Problem
Create a materialized viewfor a daily sales dashboard.

### Solution
```sql
-- Create materialized view
CREATE MATERIALIZED VIEW mv_daily_sales_dashboard AS
SELECT 
    DATE_TRUNC('day', o.order_date) AS sale_date,
    COUNT(DISTINCT o.order_id) AS order_count,
    COUNT(DISTINCT o.customer_id) AS unique_customers,
    SUM(o.total) AS daily_revenue,
    AVG(o.total) AS avg_order_value,
    SUM(oi.quantity) AS total_items_sold,
    COUNT(o.order_id) FILTER (WHERE o.status = 'delivered') AS orders_delivered
FROM orders o
INNER JOIN order_items oi ON o.order_id = oi.order_id
GROUP BY DATE_TRUNC('day', o.order_date);

-- Create unique index for concurrent refresh
CREATE UNIQUE INDEX idx_mv_daily_sales_date 
ON mv_daily_sales_dashboard(sale_date);

-- Query the materialized view (fast!)
SELECT * FROM mv_daily_sales_dashboard 
WHERE sale_date >= CURRENT_DATE - INTERVAL '30 days';

-- Refresh the data
REFRESH MATERIALIZED VIEW CONCURRENTLY mv_daily_sales_dashboard;
```

### Key Concepts
- Materialized views vs regular views, Refresh strategies, Performance optimization

---

## Challenge 6: Triggers for Auditing 🔴

**Difficulty:** Hard  
**Topic:** Audit triggers

### Problem
Create a trigger that logs all changes to the employees table.

### Solution
```sql
-- Create audit trigger function
CREATE OR REPLACE FUNCTION audit_employee_changes()
RETURNS TRIGGER AS $$
BEGIN
    IF (TG_OP = 'DELETE') THEN
        INSERT INTO employee_audit (employee_id, operation, old_values, changed_by)
        VALUES (OLD.employee_id, 'DELETE', row_to_json(OLD), current_user);
        RETURN OLD;
    ELSIF (TG_OP = 'UPDATE') THEN
        INSERT INTO employee_audit (employee_id, operation, old_values, new_values, changed_by)
        VALUES (NEW.employee_id, 'UPDATE', row_to_json(OLD), row_to_json(NEW), current_user);
        RETURN NEW;
    ELSIF (TG_OP = 'INSERT') THEN
        INSERT INTO employee_audit (employee_id, operation, new_values, changed_by)
        VALUES (NEW.employee_id, 'INSERT', row_to_json(NEW), current_user);
        RETURN NEW;
    END IF;
END;
$$ LANGUAGE plpgsql;

-- Create the trigger
CREATE TRIGGER trg_audit_employees
AFTER INSERT OR UPDATE OR DELETE ON employees
FOR EACH ROW
EXECUTE FUNCTION audit_employee_changes();

-- Test
UPDATE employees SET salary = salary * 1.05 WHERE employee_id = 10;

-- View audit log
SELECT * FROM employee_audit WHERE employee_id = 10 ORDER BY changed_at DESC;
```

### Key Concepts
- Trigger creation, Trigger functions, Audit logging, JSON data storage

---

## Challenge 7: Data Validation with Constraints 🔴

**Difficulty:** Hard  
**Topic:** Complex CHECK constraints

### Problem
Add business rule constraints for data validation.

### Solution
```sql
-- Order date validation
ALTER TABLE orders
ADD CONSTRAINT check_required_date 
CHECK (required_date IS NULL OR required_date >= order_date);

-- Employee hire date validation
ALTER TABLE employees
ADD CONSTRAINT check_hire_date_not_future 
CHECK (hire_date <= CURRENT_DATE);

-- Product pricing rule
ALTER TABLE products
ADD CONSTRAINT check_price_markup 
CHECK (price >= cost * 1.20);

-- View all constraints
SELECT constraint_name, pg_get_constraintdef(con.oid) AS definition
FROM pg_constraint con
INNER JOIN pg_class rel ON rel.oid = con.conrelid
WHERE rel.relname = 'orders';
```

### Key Concepts
- Business rule enforcement, Multi-column constraints, Database-level validation

---

## Challenge 8: Table Partitioning 🔴

**Difficulty:** Hard  
**Topic:** Table partitioning for scalability

### Problem
Create a partitioned table for storing historical orders by year.

### Solution
```sql
-- Create partitioned table
CREATE TABLE orders_partitioned (
    order_id SERIAL,
    order_number VARCHAR(50),
    customer_id INT,
    order_date DATE NOT NULL,
    total NUMERIC(10, 2)
) PARTITION BY RANGE (order_date);

-- Create partitions
CREATE TABLE orders_2023 PARTITION OF orders_partitioned
FOR VALUES FROM ('2023-01-01') TO ('2024-01-01');

CREATE TABLE orders_2024 PARTITION OF orders_partitioned
FOR VALUES FROM ('2024-01-01') TO ('2025-01-01');

-- Create indexes on partitions
CREATE INDEX ON orders_2023(customer_id);
CREATE INDEX ON orders_2024(customer_id);

-- Insert data (goes to correct partition automatically)
INSERT INTO orders_partitioned (order_number, customer_id, order_date, total)
VALUES ('ORD-2024-001', 1, '2024-06-15', 1500.00);
```

### Key Concepts
- Table partitioning, Partition pruning, Scalability strategies

---

## Challenge 9: Sequence Management 🟡

**Difficulty:** Medium  
**Topic:** Custom sequences

### Problem
Create a custom sequence for order numbers in format "ORD-YYYY-NNNNNN".

### Solution
```sql
-- Create sequence
CREATE SEQUENCE seq_order_number START WITH 1 INCREMENT BY 1;

-- Create function
CREATE OR REPLACE FUNCTION generate_order_number()
RETURNS VARCHAR AS $$
DECLARE
    next_val INT;
    year_part VARCHAR(4);
BEGIN
    next_val := nextval('seq_order_number');
    year_part := EXTRACT(YEAR FROM CURRENT_DATE)::VARCHAR;
    RETURN 'ORD-' || year_part || '-' || LPAD(next_val::TEXT, 6, '0');
END;
$$ LANGUAGE plpgsql;

-- Use as DEFAULT
ALTER TABLE orders
ALTER COLUMN order_number SET DEFAULT generate_order_number();
```

### Key Concepts
- Sequence creation, Custom ID generation, Function defaults

---

## Challenge 10: Performance Analysis 🔴

**Difficulty:** Hard  
**Topic:** Query optimization and EXPLAIN

### Problem
Optimize a slow query finding top customers.

### Solution
```sql
-- Analyze the slow query
EXPLAIN ANALYZE
SELECT 
    c.customer_name,
    COUNT(o.order_id) AS order_count,
    SUM(o.total) AS total_spent
FROM customers c
LEFT JOIN orders o ON c.customer_id = o.customer_id
WHERE c.status = 'ACTIVE'
GROUP BY c.customer_id, c.customer_name
ORDER BY total_spent DESC
LIMIT 10;

-- Add indexes based on analysis
CREATE INDEX IF NOT EXISTS idx_customers_status ON customers(status);
CREATE INDEX IF NOT EXISTS idx_orders_customer ON orders(customer_id);

-- Optimized query with CTE
EXPLAIN ANALYZE
WITH customer_totals AS (
    SELECT 
        customer_id,
        COUNT(*) AS order_count,
        SUM(total) AS total_spent
    FROM orders
    GROUP BY customer_id
)
SELECT 
    c.customer_name,
    COALESCE(ct.order_count, 0) AS order_count,
    COALESCE(ct.total_spent, 0) AS total_spent
FROM customers c
INNER JOIN customer_totals ct ON c.customer_id = ct.customer_id
WHERE c.status = 'ACTIVE'
ORDER BY ct.total_spent DESC
LIMIT 10;

-- Update statistics
ANALYZE customers;
ANALYZE orders;
```

### Key Concepts
- Query execution plans, Index usage analysis, Query optimization techniques, Database statistics

---

## 📚 Summary - Part 5: Database Design

### What You've Learned

✅ **Table Management:** CREATE TABLE with constraints, ALTER TABLE operations, Column types and defaults  
✅ **Constraints:** PRIMARY KEY, FOREIGN KEY, UNIQUE, NOT NULL, CHECK, Multi-column constraints  
✅ **Indexes:** B-tree (default), Partial indexes, Expression indexes, Composite indexes, GIN indexes  
✅ **Views & Materialized Views:** Regular views for abstraction, Materialized views for performance, Refresh strategies  
✅ **Advanced Features:** Triggers for automation, Sequences for ID generation, Table partitioning, Performance analysis

### Key Takeaways

1. **Design for integrity** - Use constraints to enforce business rules
2. **Index strategically** - Based on actual queries
3. **Views simplify** - Hide complexity, improve security
4. **Materialized views** - For expensive analytical queries
5. **Analyze before optimizing** - Use EXPLAIN ANALYZE
6. **Partitioning** - For very large tables

**Continue to:** [Part 6: Industry Advanced](file:///c:/Users/phusukale/Downloads/Docs/Repo/SQL_Challanges/sql-challenges-part6-industry-advanced.md)

**🎯 Bonus Challenges:** Design e-commerce schema from scratch, Implement soft delete pattern with triggers, Create multi-tenant database design, Build time-series data table with partitioning

**Design solid foundations! 🏗️**
