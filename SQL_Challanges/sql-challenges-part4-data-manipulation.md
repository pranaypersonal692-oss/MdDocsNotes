# SQL Challenges - Part 4: Data Manipulation (DML)

**Difficulty Range:** 🟡 Medium to 🔴 Hard  
**Total Challenges:** 12  
**Topics Covered:** INSERT, UPDATE, DELETE, MERGE/UPSERT, Transactions, Data Migration

**Database:** All challenges use `sql-practice-database.sql` (company_db)

---

## Challenge 1: Basic INSERT 🟢

**Difficulty:** Easy  
**Topic:** Single row INSERT

### Problem
Insert a new customer into the customers table.

### Requirements
- Customer name: "New Tech Solutions"
- Email: "contact@newtech.com"
- Phone: "555-2000"
- Tier: "SILVER", Credit limit: $30,000

### Solution
```sql
INSERT INTO customers (customer_name, email, phone, tier, credit_limit)
VALUES ('New Tech Solutions', 'contact@newtech.com', '555-2000', 'SILVER', 30000);

-- Verify
SELECT  * FROM customers WHERE email = 'contact@newtech.com';
```

### Key Concepts
- Basic INSERT syntax, Column list specification, Default values

---

## Challenge 2: Multiple Row INSERT 🟡

**Difficulty:** Medium  
**Topic:** Bulk INSERT

### Problem
Insert 3 new products in a single statement.

### Solution
```sql
INSERT INTO products (product_name, category_id, price, cost, quantity)
VALUES 
    ('USB-C Cable', 2, 15.99, 6.00, 300),
    ('HDMI Cable', 2, 19.99, 8.00, 250),
    ('DisplayPort Cable', 2, 24.99, 10.00, 200)
RETURNING product_id, product_name, price;
```

### Explanation
- Multiple value sets separated by commas
- All rows inserted in single transaction (atomic)
- More efficient than multiple INSERT statements

### Key Concepts
- Bulk INSERT operations, Transaction atomicity, RETURNING clause

---

## Challenge 3: INSERT from SELECT 🟡

**Difficulty:** Medium  
**Topic:** INSERT with query results

### Problem
Create inventory records for all products that don't have one yet. Set initial quantity to 0 and reorder level to 20.

### Solution
```sql
INSERT INTO inventory (product_id, quantity, reorder_level, warehouse_location)
SELECT 
    p.product_id,
    0 AS quantity,
    20 AS reorder_level,
    'WAREHOUSE-A' AS warehouse_location
FROM products p
WHERE p.product_id NOT IN (SELECT product_id FROM inventory)
RETURNING product_id, quantity, reorder_level;
```

### Explanation
- `INSERT ... SELECT` copies data from query results
- Can include calculations and transformations
- `NOT IN` finds products without inventory records
- Useful for data migration and bulk operations

### Key Concepts
- INSERT from SELECT, Conditional data insertion, Finding missing records

---

## Challenge 4: Basic UPDATE 🟡

**Difficulty:** Medium  
**Topic:** Simple UPDATE

### Problem
Increase the price of all products in category 2 by 10%.

### Solution
```sql
-- First, check what will be updated
SELECT product_id, product_name, price, price * 1.10 AS new_price
FROM products
WHERE category_id = 2;

-- Perform the update
UPDATE products
SET 
    price = price * 1.10,
    updated_at = NOW()
WHERE category_id = 2;

-- Verify
SELECT product_id, product_name, price FROM products WHERE category_id = 2;
```

### Explanation
- `UPDATE` modifies existing rows
- `SET` specifies columns and new values
- `WHERE` filters which rows to update
- ⚠️ **Without WHERE, ALL rows are updated!**

### Key Concepts
- UPDATE syntax, Calculating new values, WHERE clause importance

---

## Challenge 5: UPDATE with JOIN 🔴

**Difficulty:** Hard  
**Topic:** UPDATE using data from other tables

### Problem
Give a 5% raise to all employees in departments with budget > $400,000.

### Solution
```sql
-- PostgreSQL syntax
UPDATE employees e
SET 
    salary = salary * 1.05,
    updated_at = NOW()
FROM departments d
WHERE e.department_id = d.department_id
    AND d.budget > 400000
    AND e.status = 'ACTIVE'
RETURNING e.employee_id, e.first_name, e.last_name, e.salary;
```

### Explanation
- `FROM` clause joins with other tables
- Join condition in WHERE clause
- Can reference columns from joined tables

### Key Concepts
- UPDATE with JOIN, FROM clause in UPDATE, Cross-table conditions

---

## Challenge 6: Conditional UPDATE with CASE 🔴

**Difficulty:** Hard  
**Topic:** Complex UPDATE logic

### Problem
Update customer tiers based on their current balance:
- Balance >= $20,000 → GOLD
- Balance >= $10,000 and < $20,000 → SILVER  
- Balance < $10,000 → BRONZE

### Solution
```sql
UPDATE customers
SET tier = CASE
    WHEN current_balance >= 20000 THEN 'GOLD'
    WHEN current_balance >= 10000 THEN 'SILVER'
    ELSE 'BRONZE'
END
WHERE status = 'ACTIVE'
RETURNING customer_id, customer_name, current_balance, tier;
```

### Explanation
- CASE allows conditional logic in UPDATE
- Evaluates conditions top to bottom
- First matching condition wins
- All rows updated with appropriate tier

### Key Concepts
- CASE in UPDATE, Conditional data updates, Business rule implementation

---

## Challenge 7: Basic DELETE 🟡

**Difficulty:** Medium  
**Topic:** DELETE with conditions

### Problem
Delete all orders with status 'cancelled' that are older than 90 days.

### Solution
```sql
-- Preview what will be deleted
SELECT order_id, customer_id, order_date, status
FROM orders
WHERE status = 'cancelled' 
    AND order_date < CURRENT_DATE - INTERVAL '90 days';

-- Perform the delete
DELETE FROM orders
WHERE status = 'cancelled' 
    AND order_date < CURRENT_DATE - INTERVAL '90 days'
RETURNING order_id, customer_id, order_date;
```

### Explanation
- `DELETE FROM` removes rows
- `WHERE` specifies which rows to delete
- ⚠️ **Without WHERE, ALL rows are deleted!**
- Always preview with SELECT first
- RETURNING shows what was deleted

### Key Concepts
- DELETE syntax, Date calculations, Data cleanup, Verification before deletion

### Soft Delete Alternative
```sql
-- Instead of deleting, mark as deleted
UPDATE orders
SET deleted_at = NOW(), status = 'archived'
WHERE status = 'cancelled' 
    AND order_date < CURRENT_DATE - INTERVAL '90 days';
```

---

## Challenge 8: DELETE with Subquery 🔴

**Difficulty:** Hard  
**Topic:** DELETE using related data

### Problem
Delete all products that have never been ordered.

### Solution
```sql
-- Preview products to be deleted
SELECT p.product_id, p.product_name
FROM products p
LEFT JOIN order_items oi ON p.product_id = oi.product_id
WHERE oi.product_id IS NULL;

-- Delete products never ordered
DELETE FROM products
WHERE product_id NOT IN (
    SELECT DISTINCT product_id 
    FROM order_items
)
RETURNING product_id, product_name;
```

### Explanation
- Subquery finds products in order_items
- `NOT IN` identifies products NOT in that list
- Removes orphaned/unused products
- Be careful with foreign key constraints

### Key Concepts
- DELETE with subquery, NOT IN pattern, Finding orphaned records

---

## Challenge 9: UPSERT with ON CONFLICT 🔴

**Difficulty:** Hard  
**Topic:** INSERT with conflict handling

### Problem
Insert or update inventory records: If product already has inventory, increase quantity by 100; otherwise create new record with quantity 100.

### Solution
```sql
-- PostgreSQL UPSERT syntax
INSERT INTO inventory (product_id, quantity, reorder_level, warehouse_location)
VALUES (1, 100, 20, 'WAREHOUSE-A')
ON CONFLICT (product_id) 
DO UPDATE SET 
    quantity = inventory.quantity + EXCLUDED.quantity,
    updated_at = NOW()
RETURNING *;

-- For multiple products
INSERT INTO inventory (product_id, quantity, reorder_level, warehouse_location)
VALUES 
    (1, 100, 20, 'WAREHOUSE-A'),
    (2, 150, 30, 'WAREHOUSE-B'),
    (3, 200, 25, 'WAREHOUSE-A')
ON CONFLICT (product_id)
DO UPDATE SET 
    quantity = inventory.quantity + EXCLUDED.quantity,
    updated_at = NOW()
RETURNING product_id, quantity;
```

### Explanation
- `ON CONFLICT` handles unique constraint violations
- `DO UPDATE` specifies what to do on conflict
- `EXCLUDED` refers to the values being inserted
- `inventory.quantity` is existing, `EXCLUDED.quantity` is new
- Atomic operation (insert or update, never both)

### Key Concepts
- UPSERT pattern, ON CONFLICT clause, EXCLUDED keyword, Atomic operations

---

## Challenge 10: Transaction Management 🔴

**Difficulty:** Hard  
**Topic:** BEGIN, COMMIT, ROLLBACK

### Problem
Transfer $1000 from account 'ACC-1000001' to account 'ACC-1000003'. Ensure both operations succeed or both fail.

### Solution
```sql
-- Start transaction
BEGIN;

-- Debit source account
UPDATE accounts
SET balance = balance - 1000
WHERE account_number = 'ACC-1000001'
    AND balance >= 1000;

-- Check if update succeeded
-- If 0 rows, account doesn't exist or insufficient funds

-- Credit destination account
UPDATE accounts
SET balance = balance + 1000
WHERE account_number = 'ACC-1000003';

-- Log transaction
INSERT INTO transaction_log (from_account, to_account, amount)
SELECT 
    (SELECT account_id FROM accounts WHERE account_number = 'ACC-1000001'),
    (SELECT account_id FROM accounts WHERE account_number = 'ACC-1000003'),
    1000;

-- Verify balances
SELECT account_number, balance 
FROM accounts 
WHERE account_number IN ('ACC-1000001', 'ACC-1000003');

-- If everything looks good, commit
COMMIT;

-- If something went wrong, rollback instead:
-- ROLLBACK;
```

### Explanation
- `BEGIN` starts a transaction
- All statements execute as one unit
- `COMMIT` makes changes permanent
- `ROLLBACK` undoes all changes
- Transaction ensures atomicity (all or nothing)

### Key Concepts
- Transaction boundaries, ACID properties, COMMIT vs ROLLBACK, Data consistency

---

## Challenge 11: Bulk UPDATE with CTE 🔴

**Difficulty:** Hard  
**Topic:** UPDATE using CTE

### Problem
Update order totals to match the sum of their order items (fix any discrepancies).

### Solution
```sql
WITH order_totals AS (
    SELECT 
        order_id,
        SUM(quantity * unit_price * (1 - COALESCE(discount, 0))) AS calculated_total
    FROM order_items
    GROUP BY order_id
)
UPDATE orders o
SET 
    total = ot.calculated_total,
    updated_at = NOW()
FROM order_totals ot
WHERE o.order_id = ot.order_id
    AND o.total != ot.calculated_total
RETURNING o.order_id, o.total AS new_total;
```

### Explanation
- CTE calculates correct totals from line items
- UPDATE uses CTE to find correct values
- Only updates orders with discrepancies
- More readable than complex subqueries

### Key Concepts
- CTE with UPDATE, Data reconciliation, Calculated updates

---

## Challenge 12: Cascading DELETE 🔴

**Difficulty:** Hard  
**Topic:** DELETE with foreign key cascades

### Problem
Analyze the impact and delete a customer (understanding cascade behavior).

### Solution
```sql
-- Step 1: Analyze impact
SELECT 
    'Customer' AS record_type,
    COUNT(*) AS count
FROM customers WHERE customer_id = 16
UNION ALL
SELECT 'Orders', COUNT(*)
FROM orders WHERE customer_id = 16
UNION ALL
SELECT 'Order Items', COUNT(*)
FROM order_items oi
INNER JOIN orders o ON oi.order_id = o.order_id
WHERE o.customer_id = 16;

-- Step 2: Backup if needed
CREATE TEMP TABLE deleted_customer_backup AS
SELECT * FROM customers WHERE customer_id = 16;

-- Step 3: Perform DELETE
-- If ON DELETE CASCADE is set, related records auto-delete
DELETE FROM customers
WHERE customer_id = 16
RETURNING *;

-- Step 4: Verify
SELECT * FROM orders WHERE customer_id = 16;  -- Should be empty if cascaded
```

### Explanation
- Foreign keys with ON DELETE CASCADE auto-delete related rows
- Always preview impact before deleting
- Consider backup for important deletes
- Understand cascade effects on data integrity

### Key Concepts
- CASCADE behavior, Foreign key constraints, Impact analysis, Data backup strategies

---

## 📚 Summary - Part 4: Data Manipulation

### What You've Learned

✅ **INSERT Operations:** Single row, Multiple rows (bulk), INSERT from SELECT, RETURNING clause  
✅ **UPDATE Operations:** Basic UPDATE with WHERE, UPDATE with JOIN, Conditional UPDATE (CASE), UPDATE with CTE  
✅ **DELETE Operations:** DELETE with conditions, DELETE with subqueries, Soft delete pattern, CASCADE behavior  
✅ **Advanced Patterns:** UPSERT (ON CONFLICT), Transaction management, Bulk operations, Data reconciliation

### Key Takeaways

1. **Always use WHERE** in UPDATE/DELETE (or you'll affect all rows!)
2. **Preview first** - SELECT before UPDATE/DELETE
3. **Use transactions** for multi-step operations
4. **RETURNING is powerful** - Shows affected rows
5. **UPSERT is atomic** - No race conditions
6. **Understand CASCADE** - Know what gets deleted

### Critical Safety Rules

⚠️ **Before UPDATE/DELETE:**
```sql
-- 1. Preview with SELECT
SELECT * FROM table WHERE condition;
-- 2. Perform operation
UPDATE/DELETE FROM table WHERE condition;
-- 3. Verify result
SELECT * FROM table WHERE condition;
```

⚠️ **For Critical Operations:**
```sql
BEGIN;
-- Execute statements
UPDATE/DELETE...
-- Verify
SELECT...
-- If good: COMMIT, if bad: ROLLBACK
COMMIT; -- or ROLLBACK;
```

**Continue to:** [Part 5: Database Design](file:///c:/Users/phusukale/Downloads/Docs/Repo/SQL_Challanges/sql-challenges-part5-database-design.md)

**🎯 Bonus Challenges:** Implement audit trail, Build data archival process, Create optimistic locking with version numbers, Batch update customer tiers based on order history

**Practice safe data manipulation! 🛡️**
