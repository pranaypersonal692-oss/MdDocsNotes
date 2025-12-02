# SQL Challenges - Part 1: Fundamentals

**Difficulty Range:** 🟢 Easy to 🟡 Medium  
**Total Challenges:** 15  
**Topics Covered:** SELECT basics, WHERE filtering, ORDER BY, LIMIT, Basic aggregations, DISTINCT

---

## Challenge 1: Select All Employees 🟢

**Difficulty:** Easy  
**Topic:** Basic SELECT

### Problem
Retrieve all information about all employees in the company.

### Expected Output
All columns from the employees table for all rows.

### Solution
```sql
SELECT * 
FROM employees;
```

### Explanation
- `SELECT *` retrieves all columns
- `FROM employees` specifies the table
- No WHERE clause means all rows are returned

### Key Concepts
- Basic SELECT syntax
- The asterisk (*) wildcard for all columns
- FROM clause to specify data source

### Best Practice
⚠️ In production code, avoid `SELECT *`:
- Specify needed columns explicitly for better performance
- Makes code more maintainable
- Reduces network bandwidth

### Better Approach
```sql
SELECT employee_id, first_name, last_name, email, job_title, salary
FROM employees;
```

---

## Challenge 2: Select Specific Columns 🟢

**Difficulty:** Easy  
**Topic:** Column projection

### Problem
Display only the first name, last name, and job title of all employees.

### Expected Output
```
first_name | last_name | job_title
-----------+-----------+----------
John       | Smith     | CEO
Sarah      | Johnson   | CFO
...
```

### Solution
```sql
SELECT first_name, last_name, job_title
FROM employees;
```

### Explanation
- List only the columns you need
- Columns appear in the order specified
- Improves query performance by reducing data transfer

### Key Concepts
- Column projection (selecting specific columns)
- Column ordering in result set

### Variation - Using Aliases
```sql
SELECT 
    first_name AS "First Name",
    last_name AS "Last Name",
    job_title AS "Position"
FROM employees;
```

---

## Challenge 3: Filter by Department 🟢

**Difficulty:** Easy  
**Topic:** WHERE clause with equality

### Problem
Find all employees who work in department with ID 2 (Sales department).

### Expected Output
```
first_name | last_name | job_title
-----------+-----------+------------------
Emily      | Brown     | VP Sales
David      | Jones     | Sales Manager
Lisa       | Davis     | Sales Representative
...
```

### Solution
```sql
SELECT first_name, last_name, job_title
FROM employees
WHERE department_id = 2;
```

### Explanation
- `WHERE department_id = 2` filters rows
- Only rows matching the condition are returned
- Equality operator `=` for exact match

### Key Concepts
- WHERE clause for filtering
- Equality comparison operator
- Filtering numeric values

### Variation - Multiple Departments
```sql
SELECT first_name, last_name, job_title
FROM employees
WHERE department_id IN (2, 4, 6);  -- Sales, Engineering, Finance
```

---

## Challenge 4: Filter by Salary Range 🟢

**Difficulty:** Easy  
**Topic:** WHERE clause with range conditions

### Problem
Find all employees earning between $70,000 and $100,000 (inclusive).

### Expected Output
Employees with salaries in the specified range.

### Solution
```sql
SELECT first_name, last_name, job_title, salary
FROM employees
WHERE salary >= 70000 AND salary <= 100000
ORDER BY salary DESC;
```

### Explanation
- `AND` combines multiple conditions
- Both conditions must be true
- `>=` and `<=` for inclusive range
- `ORDER BY salary DESC` sorts highest to lowest

### Key Concepts
- Range filtering with AND
- Comparison operators (>=, <=)
- Combining multiple conditions

### Alternative - Using BETWEEN
```sql
SELECT first_name, last_name, job_title, salary
FROM employees
WHERE salary BETWEEN 70000 AND 100000
ORDER BY salary DESC;
```

**Note:** BETWEEN is inclusive on both ends.

---

## Challenge 5: Pattern Matching with LIKE 🟢

**Difficulty:** Easy  
**Topic:** String pattern matching

### Problem
Find all employees whose first name starts with 'J'.

### Expected Output
```
first_name | last_name | email
-----------+-----------+----------------------
John       | Smith     | john.smith@company.com
James      | Miller    | james.miller@company.com
Jennifer   | Wilson    | jennifer.wilson@...
...
```

### Solution
```sql
SELECT first_name, last_name, email
FROM employees
WHERE first_name LIKE 'J%';
```

### Explanation
- `LIKE` operator for pattern matching
- `%` wildcard matches zero or more characters
- `'J%'` matches any string starting with 'J'

### Key Concepts
- LIKE operator
- Wildcards: `%` (any characters), `_` (single character)
- Case-sensitive matching (depends on database collation)

### Variations
```sql
-- Names ending with 'son'
WHERE last_name LIKE '%son';

-- Names containing 'and' anywhere
WHERE first_name LIKE '%and%';

-- Names with exactly 4 characters ending in 'ary'
WHERE first_name LIKE '_ary';

-- Case-insensitive matching (PostgreSQL)
WHERE first_name ILIKE 'j%';
```

---

## Challenge 6: NULL Value Handling 🟡

**Difficulty:** Medium  
**Topic:** NULL checks

### Problem
Find all employees who do not have a manager (CEO and top executives).

### Expected Output
```
first_name | last_name | job_title
-----------+-----------+-----------
John       | Smith     | CEO
```

### Solution
```sql
SELECT first_name, last_name, job_title
FROM employees
WHERE manager_id IS NULL;
```

### Explanation
- `IS NULL` checks for NULL values
- Cannot use `= NULL` (always evaluates to NULL, not TRUE)
- NULL represents missing or unknown data

### Key Concepts
- NULL value handling
- IS NULL vs IS NOT NULL
- NULL is not equal to anything, including NULL

### Common Mistakes
```sql
-- ❌ WRONG - This won't work!
WHERE manager_id = NULL;

-- ✅ CORRECT
WHERE manager_id IS NULL;

-- Find employees WITH a manager
WHERE manager_id IS NOT NULL;
```

---

## Challenge 7: Sorting Results 🟢

**Difficulty:** Easy  
**Topic:** ORDER BY

### Problem
List all employees sorted by salary from highest to lowest. If salaries are equal, sort by last name alphabetically.

### Expected Output
```
first_name | last_name | salary
-----------+-----------+---------
John       | Smith     | 250000.00
Michael    | Williams  | 200000.00
Sarah      | Johnson   | 180000.00
...
```

### Solution
```sql
SELECT first_name, last_name, salary
FROM employees
ORDER BY salary DESC, last_name ASC;
```

### Explanation
- `ORDER BY` sorts results
- `DESC` = descending (high to low)
- `ASC` = ascending (low to high) - default
- Multiple columns: sorts by first, then second for ties

### Key Concepts
- Single and multi-column sorting
- ASC vs DESC
- Sort order priority

### Variations
```sql
-- Sort by hire date, newest first
ORDER BY hire_date DESC;

-- Sort by department, then salary within each department
ORDER BY department_id ASC, salary DESC;

-- Sort with NULL values last
ORDER BY manager_id ASC NULLS LAST;
```

---

## Challenge 8: Limiting Results 🟢

**Difficulty:** Easy  
**Topic:** LIMIT and OFFSET

### Problem
Find the top 5 highest-paid employees.

### Expected Output
Top 5 rows sorted by salary.

### Solution
```sql
SELECT first_name, last_name, job_title, salary
FROM employees
ORDER BY salary DESC
LIMIT 5;
```

### Explanation
- `LIMIT 5` restricts output to 5 rows
- Must use ORDER BY to get consistent "top" results
- Without ORDER BY, LIMIT returns arbitrary rows

### Key Concepts
- LIMIT clause
- Combining ORDER BY with LIMIT
- Top-N queries

### Pagination Example
```sql
-- First page (rows 1-5)
LIMIT 5 OFFSET 0;

-- Second page (rows 6-10)
LIMIT 5 OFFSET 5;

-- Third page (rows 11-15)
LIMIT 5 OFFSET 10;
```

---

## Challenge 9: Counting Rows 🟢

**Difficulty:** Easy  
**Topic:** COUNT aggregate

### Problem
Count how many employees work in the company.

### Expected Output
```
total_employees
-----------------
37
```

### Solution
```sql
SELECT COUNT(*) AS total_employees
FROM employees;
```

### Explanation
- `COUNT(*)` counts all rows
- Returns a single number
- `AS total_employees` provides a readable column name

### Key Concepts
- COUNT aggregate function
- Column aliases with AS
- Aggregate functions return single value

### Variations
```sql
-- Count employees with managers (exclude NULLs)
SELECT COUNT(manager_id) AS employees_with_manager
FROM employees;

-- Count active employees only
SELECT COUNT(*) AS active_employees
FROM employees
WHERE status = 'ACTIVE';

-- Count distinct departments
SELECT COUNT(DISTINCT department_id) AS department_count
FROM employees;
```

---

## Challenge 10: SUM and AVG Aggregates 🟡

**Difficulty:** Medium  
**Topic:** Aggregate functions

### Problem
Calculate the total payroll (sum of all salaries) and average salary for the company.

### Expected Output
```
total_payroll | average_salary
--------------+----------------
4256000.00    | 115029.73
```

### Solution
```sql
SELECT 
    SUM(salary) AS total_payroll,
    AVG(salary) AS average_salary
FROM employees
WHERE status = 'ACTIVE';
```

### Explanation
- `SUM(salary)` adds all salary values
- `AVG(salary)` calculates arithmetic mean
- Multiple aggregates in one query
- WHERE filters before aggregation

### Key Concepts
- SUM and AVG functions
- Multiple aggregates in SELECT
- Filtering before aggregation

### Rounding Average
```sql
SELECT 
    SUM(salary) AS total_payroll,
    ROUND(AVG(salary), 2) AS average_salary,
    COUNT(*) AS employee_count
FROM employees
WHERE status = 'ACTIVE';
```

---

## Challenge 11: MIN and MAX Values 🟢

**Difficulty:** Easy  
**Topic:** MIN/MAX aggregates

### Problem
Find the lowest and highest salaries in the company.

### Expected Output
```
lowest_salary | highest_salary
--------------+----------------
55000.00      | 250000.00
```

### Solution
```sql
SELECT 
    MIN(salary) AS lowest_salary,
    MAX(salary) AS highest_salary
FROM employees;
```

### Explanation
- `MIN()` finds the smallest value
- `MAX()` finds the largest value
- Work with numbers, dates, and strings

### Key Concepts
- MIN and MAX functions
- Finding extremes in datasets

### With Additional Context
```sql
-- Find employees with min and max salaries
SELECT first_name, last_name, salary
FROM employees
WHERE salary = (SELECT MIN(salary) FROM employees)
   OR salary = (SELECT MAX(salary) FROM employees);
```

---

## Challenge 12: DISTINCT Values 🟢

**Difficulty:** Easy  
**Topic:** DISTINCT keyword

### Problem
List all unique job titles in the company.

### Expected Output
```
job_title
------------------
CEO
CFO
CTO
VP Sales
Sales Manager
...
```

### Solution
```sql
SELECT DISTINCT job_title
FROM employees
ORDER BY job_title;
```

### Explanation
- `DISTINCT` removes duplicate values
- Returns each unique value once
- Can be used with multiple columns

### Key Concepts
- DISTINCT keyword
- Removing duplicates
- Unique value identification

### Multiple Column DISTINCT
```sql
-- Unique combinations of department and job title
SELECT DISTINCT department_id, job_title
FROM employees
ORDER BY department_id, job_title;
```

---

## Challenge 13: Combining Conditions with AND/OR 🟡

**Difficulty:** Medium  
**Topic:** Complex WHERE conditions

### Problem
Find employees who either:
- Work in Sales (dept 2) with salary > $65,000, OR
- Work in Engineering (dept 4) with salary > $90,000

### Expected Output
Employees meeting either condition.

### Solution
```sql
SELECT first_name, last_name, job_title, department_id, salary
FROM employees
WHERE (department_id = 2 AND salary > 65000)
   OR (department_id = 4 AND salary > 90000)
ORDER BY department_id, salary DESC;
```

### Explanation
- Parentheses group conditions
- `OR` means either condition can be true
- `AND` requires both conditions in the group to be true
- Parentheses are crucial for correct logic

### Key Concepts
- Combining AND/OR operators
- Operator precedence
- Parentheses for grouping

### Common Mistake
```sql
-- ❌ WRONG - Without parentheses, logic is different!
WHERE department_id = 2 AND salary > 65000
   OR department_id = 4 AND salary > 90000;

-- ✅ CORRECT - Explicit parentheses
WHERE (department_id = 2 AND salary > 65000)
   OR (department_id = 4 AND salary > 90000);
```

---

## Challenge 14: IN Operator 🟢

**Difficulty:** Easy  
**Topic:** IN operator

### Problem
Find all products in categories 1, 2, or 3.

### Expected Output
Products matching the specified categories.

### Solution
```sql
SELECT product_id, product_name, category_id, price
FROM products
WHERE category_id IN (1, 2, 3)
ORDER BY category_id, price DESC;
```

### Explanation
- `IN` operator checks if value matches any in a list
- Cleaner than multiple OR conditions
- Works with numbers, strings, and dates

### Key Concepts
- IN operator syntax
- Alternative to multiple OR conditions
- List-based filtering

### Equivalent OR Version
```sql
-- This does the same thing but is more verbose
WHERE category_id = 1 
   OR category_id = 2 
   OR category_id = 3;

-- IN is more concise:
WHERE category_id IN (1, 2, 3);
```

### NOT IN Example
```sql
-- Products NOT in categories 1, 2, 3
WHERE category_id NOT IN (1, 2, 3);
```

---

## Challenge 15: String Concatenation & Aliases 🟡

**Difficulty:** Medium  
**Topic:** String operations, calculated columns

### Problem
Create a full name column by combining first and last names, and format it as "LASTNAME, Firstname". Also show their email and calculate their monthly salary (annual ÷ 12).

### Expected Output
```
full_name          | email                    | monthly_salary
-------------------+--------------------------+----------------
SMITH, John        | john.smith@company.com   | 20833.33
JOHNSON, Sarah     | sarah.johnson@company.com| 15000.00
...
```

### Solution
```sql
SELECT 
    UPPER(last_name) || ', ' || first_name AS full_name,
    email,
    ROUND(salary / 12, 2) AS monthly_salary
FROM employees
WHERE status = 'ACTIVE'
ORDER BY last_name, first_name;
```

### Explanation
- `||` is PostgreSQL concatenation operator
- `UPPER()` converts to uppercase
- `ROUND(x, 2)` rounds to 2 decimal places
- Calculated columns create new values from existing ones

### Key Concepts
- String concatenation
- String functions (UPPER, LOWER)
- Calculated/computed columns
- ROUND function for numbers

### Alternative Syntax
```sql
-- Using CONCAT function
SELECT 
    CONCAT(UPPER(last_name), ', ', first_name) AS full_name,
    email,
    ROUND(salary / 12, 2) AS monthly_salary
FROM employees;

-- Adding formatted salary display
SELECT 
    first_name || ' ' || last_name AS full_name,
    '$' || TO_CHAR(salary, '999,999.99') AS formatted_salary
FROM employees;
```

---

## 📚 Summary - Part 1: Fundamentals

### What You've Learned

✅ **Basic SELECT Operations**
- Selecting all columns (*)
- Selecting specific columns
- Using column aliases

✅ **Filtering Data**
- WHERE clause with various operators
- Comparison operators (=, >, <, >=, <=, <>)
- Pattern matching with LIKE
- NULL value handling (IS NULL, IS NOT NULL)
- IN operator
- Combining conditions (AND, OR)

✅ **Sorting & Limiting**
- ORDER BY for sorting (ASC, DESC)
- Multi-column sorting
- LIMIT for restricting rows
- OFFSET for pagination

✅ **Basic Aggregations**
- COUNT - counting rows
- SUM - adding values
- AVG - calculating averages
- MIN/MAX - finding extremes
- DISTINCT - removing duplicates

✅ **String & Math Operations**
- String concatenation (||, CONCAT)
- String functions (UPPER, LOWER)
- Mathematical calculations
- ROUND function

### Key Takeaways

1. **Always specify columns** instead of using SELECT * in production
2. **Use IS NULL** not = NULL for NULL checks
3. **Order matters** in ORDER BY with multiple columns
4. **Parentheses are crucial** when combining AND/OR operators
5. **LIMIT needs ORDER BY** for consistent results
6. **DISTINCT** operates on all selected columns

### Practice Recommendations

1. ✍️ Rewrite each query from memory
2. 🔄 Modify conditions and observe results
3. 🧪 Combine multiple concepts in one query
4. 📊 Try queries on different tables
5. ⚡ Check query performance with EXPLAIN

### Next Steps

Ready for Part 2? You'll learn:
- JOINs (combining data from multiple tables)
- GROUP BY (aggregating data by categories)
- HAVING (filtering aggregated data)
- Subqueries
- CASE statements

**Continue to:** [Part 2: Intermediate Queries](file:///c:/Users/phusukale/Downloads/Docs/Repo/SQL_Challanges/sql-challenges-part2-intermediate.md)

---

## 🎯 Bonus Practice Challenges

Try these additional challenges to reinforce your learning:

1. Find all customers with 'LLC' or 'Inc' in their name
2. List products with price between $50 and $150
3. Find the 10 cheapest products
4. Count how many products are in each category
5. Find employees hired in 2018 or later
6. List all distinct cities where the company has locations
7. Calculate the total value of all inventory (quantity × price)
8. Find products with quantity less than their reorder level
9. List customers sorted by current balance (highest first)
10. Find the average product price, rounded to nearest dollar

**Good luck! 🚀**
