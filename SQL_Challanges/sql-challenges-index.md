# 🎯 SQL Practice Challenges - Complete Guide

## 📚 Overview

Welcome to the comprehensive SQL practice guide! This collection contains **79 hands-on challenges** progressing from beginner to industry-advanced levels. Each challenge includes detailed solutions, explanations, and best practices.

## 🗄️ Database Schema

All challenges use the `company_db` database with the following main tables:
- **employees** - Employee information with hierarchy
- **departments** - Department details with budgets
- **customers** - Customer accounts with tiers (GOLD/SILVER/BRONZE)
- **products** - Product catalog with pricing
- **orders** & **order_items** - Sales transactions
- **inventory** - Stock management
- **accounts** - Financial accounts
- **sales** - Analytics data
- And many more specialized tables...

## 📖 Challenge Guides

### Part 1: Fundamentals (Beginner)
**File:** [sql-challenges-part1-fundamentals.md](file:///c:/Users/phusukale/Downloads/Docs/Repo/SQL_Challanges/sql-challenges-part1-fundamentals.md)

- SELECT basics & column selection
- WHERE clause filtering
- ORDER BY & LIMIT
- Basic aggregate functions (COUNT, SUM, AVG)
- DISTINCT operations

**Difficulty:** 🟢 Easy to 🟡 Medium  
**Challenges:** 15 challenges

---

### Part 2: Intermediate Queries
**File:** [sql-challenges-part2-intermediate.md](file:///c:/Users/phusukale/Downloads/Docs/Repo/SQL_Challanges/sql-challenges-part2-intermediate.md)

- INNER JOIN operations
- LEFT/RIGHT/FULL OUTER JOINs
- GROUP BY & HAVING clauses
- Basic subqueries
- CASE statements & conditional logic

**Difficulty:** 🟡 Medium  
**Challenges:** 15 challenges

---

### Part 3: Advanced Queries
**File:** [sql-challenges-part3-advanced.md](file:///c:/Users/phusukale/Downloads/Docs/Repo/SQL_Challanges/sql-challenges-part3-advanced.md)

- Window functions (ROW_NUMBER, RANK, DENSE_RANK)
- CTEs (Common Table Expressions)
- Self-joins & complex JOINs
- Correlated subqueries
- Advanced aggregations

**Difficulty:** 🟡 Medium to 🔴 Hard  
**Challenges:** 15 challenges

---

### Part 4: Data Manipulation (DML)
**File:** [sql-challenges-part4-data-manipulation.md](file:///c:/Users/phusukale/Downloads/Docs/Repo/SQL_Challanges/sql-challenges-part4-data-manipulation.md)

- INSERT operations (single & bulk)
- UPDATE operations (simple & complex)
- DELETE operations with constraints
- MERGE/UPSERT patterns
- Data migration scenarios

**Difficulty:** 🟡 Medium to 🔴 Hard  
**Challenges:** 12 challenges

---

### Part 5: Database Design & Administration
**File:** [sql-challenges-part5-database-design.md](file:///c:/Users/phusukale/Downloads/Docs/Repo/SQL_Challanges/sql-challenges-part5-database-design.md)

- CREATE TABLE with constraints
- Indexes & query optimization
- Views & materialized views
- Transactions & ACID properties
- Schema design patterns

**Difficulty:** 🔴 Hard  
**Challenges:** 10 challenges

---

### Part 6: Industry Advanced Topics
**File:** [sql-challenges-part6-industry-advanced.md](file:///c:/Users/phusukale/Downloads/Docs/Repo/SQL_Challanges/sql-challenges-part6-industry-advanced.md)

- Recursive queries (WITH RECURSIVE)
- Query performance optimization
- Complex analytical queries
- Real-world business scenarios
- Advanced PostgreSQL features

**Difficulty:** 🔴 Hard to 🔥 Expert  
**Challenges:** 12 challenges

---

## 🎓 How to Use This Guide

### 1. Setup Database
```sql
-- Run the sql-practice-database.sql file to setup the database
psql -U your_username -d postgres -f sql-practice-database.sql
```

### 2. Choose Your Path

**Beginner Path:**
Start with Part 1 → Part 2 → Practice until comfortable

**Intermediate Path:**
Review Part 1 → Focus on Part 2 & Part 3

**Advanced Path:**
Jump to Part 4+ for real-world challenges

### 3. Challenge Format

Each challenge follows this structure:
- **Difficulty Level**: 🟢 Easy / 🟡 Medium / 🔴 Hard / 🔥 Expert
- **Problem Statement**: Clear description of requirements
- **Expected Output**: Sample of what results should look like
- **Solution**: Complete SQL query
- **Explanation**: Step-by-step breakdown
- **Key Concepts**: What you're learning
- **Variations**: Alternative approaches or optimizations

### 4. Practice Tips

✅ **Try Before Looking**: Attempt each challenge before viewing the solution  
✅ **Understand, Don't Memorize**: Focus on understanding the approach  
✅ **Experiment**: Modify queries to see how they behave  
✅ **Check Execution Plans**: Use `EXPLAIN` to understand query performance  
✅ **Review Key Concepts**: Each challenge highlights important concepts  

---

## 📊 Difficulty Distribution

| Level | Count | Percentage |
|-------|-------|-----------|
| 🟢 Easy | 15 | 19% |
| 🟡 Medium | 35 | 44% |
| 🔴 Hard | 24 | 30% |
| 🔥 Expert | 6 | 7% |
| **Total** | **79** | **100%** |

---

## 🔑 Key SQL Concepts Covered

### Querying
- SELECT projections & aliases
- WHERE filtering (AND, OR, NOT, IN, BETWEEN, LIKE)
- JOINs (INNER, LEFT, RIGHT, FULL, CROSS, SELF)
- Subqueries (scalar, row, table, correlated)
- Set operations (UNION, INTERSECT, EXCEPT)

### Aggregation & Grouping
- Aggregate functions (COUNT, SUM, AVG, MIN, MAX)
- GROUP BY with multiple columns
- HAVING clause for filtered aggregates
- Window functions (OVER, PARTITION BY)
- Running totals & moving averages

### Advanced Features
- Common Table Expressions (CTEs)
- Recursive queries
- Window functions (ROW_NUMBER, RANK, DENSE_RANK, LAG, LEAD)
- CASE statements & conditional logic
- JSON operations

### Data Manipulation
- INSERT (single, multiple, from SELECT)
- UPDATE (simple, with JOINs, conditional)
- DELETE (with constraints, cascading)
- MERGE/UPSERT operations
- Transaction management

### Database Design
- Table creation with constraints
- Primary & foreign keys
- Indexes (B-tree, partial, expression)
- Views & materialized views
- Triggers & stored procedures

---

## 🛠️ Useful Commands for Practice

### View Database Structure
```sql
-- List all tables
\dt

-- Describe a table structure
\d employees

-- View all indexes
\di
```

### Performance Analysis
```sql
-- Show query execution plan
EXPLAIN SELECT * FROM employees;

-- Show detailed execution with actual times
EXPLAIN ANALYZE SELECT * FROM employees;
```

### Reset Data
If you need to reset the database to original state, simply re-run:
```sql
psql -U your_username -d postgres -f sql-practice-database.sql
```

---

## 📝 Learning Path Recommendations

### Week 1-2: Fundamentals
- Complete Part 1: Fundamentals
- Focus on SELECT, WHERE, ORDER BY
- Practice aggregate functions

### Week 3-4: Joins & Grouping
- Complete Part 2: Intermediate Queries
- Master all JOIN types
- Practice GROUP BY extensively

### Week 5-6: Advanced Queries
- Complete Part 3: Advanced Queries
- Learn window functions thoroughly
- Practice CTEs and subqueries

### Week 7-8: Data Manipulation
- Complete Part 4: Data Manipulation
- Practice INSERT/UPDATE/DELETE
- Learn transaction management

### Week 9-10: Design & Optimization
- Complete Part 5: Database Design
- Study indexes and performance
- Practice schema design

### Week 11-12: Industry Scenarios
- Complete Part 6: Industry Advanced
- Work on complex business problems
- Optimize query performance

---

## 🎯 Challenge Yourself

After completing all guides:

1. **Time Yourself**: Retry challenges with time limits
2. **Optimize**: Rewrite queries for better performance
3. **Explain Plans**: Analyze and understand execution plans
4. **Real Data**: Apply concepts to your own projects
5. **Teach Others**: Best way to solidify knowledge

---

## 📚 Additional Resources

- [PostgreSQL Official Documentation](https://www.postgresql.org/docs/)
- [SQL Style Guide](https://www.sqlstyle.guide/)
- [Use The Index, Luke](https://use-the-index-luke.com/) - SQL Performance Guide

---

## 🤝 Contributing

Found an error or have a better solution? Feel free to:
- Suggest improvements
- Add alternative solutions
- Share optimization tips

---

**Happy Learning! 🚀**

*Remember: The best way to learn SQL is by writing queries. Don't just read - practice!*
