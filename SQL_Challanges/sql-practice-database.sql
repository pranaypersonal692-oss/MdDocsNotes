-- =====================================================
-- SQL PRACTICE DATABASE
-- Complete Schema and Sample Data for SQL Guide
-- Database: company_db
-- =====================================================

-- This file contains complete database schema and sample data
-- to practice all examples from the comprehensive SQL guide.

-- =====================================================
-- DROP EXISTING TABLES (if needed)
-- =====================================================

DROP TABLE IF EXISTS trigger_debug_log CASCADE;
DROP TABLE IF EXISTS billing_errors CASCADE;
DROP TABLE IF EXISTS batch_log CASCADE;
DROP TABLE IF EXISTS notification_queue CASCADE;
DROP TABLE IF EXISTS usage_charges CASCADE;
DROP TABLE IF EXISTS invoices CASCADE;
DROP TABLE IF EXISTS error_log CASCADE;
DROP TABLE IF EXISTS inventory_log CASCADE;
DROP TABLE IF EXISTS inventory CASCADE;
DROP TABLE IF EXISTS transaction_log CASCADE;
DROP TABLE IF EXISTS employee_audit CASCADE;
DROP TABLE IF EXISTS order_audit CASCADE;
DROP TABLE IF EXISTS order_items CASCADE;
DROP TABLE IF EXISTS orders CASCADE;
DROP TABLE IF EXISTS products CASCADE;
DROP TABLE IF EXISTS customers CASCADE;
DROP TABLE IF EXISTS locations CASCADE;
DROP TABLE IF EXISTS departments CASCADE;
DROP TABLE IF EXISTS employees CASCADE;
DROP TABLE IF EXISTS accounts CASCADE;
DROP TABLE IF EXISTS sales CASCADE;
DROP TABLE IF EXISTS exchange_rates CASCADE;
DROP TABLE IF EXISTS bill_of_materials CASCADE;
DROP TABLE IF EXISTS flights CASCADE;
DROP TABLE IF EXISTS report_jobs CASCADE;
DROP TABLE IF EXISTS audit_log CASCADE;

-- =====================================================
-- CORE BUSINESS TABLES
-- =====================================================

-- Locations Table
CREATE TABLE locations (
    location_id SERIAL PRIMARY KEY,
    street_address VARCHAR(100),
    city VARCHAR(50),
    state_province VARCHAR(50),
    country VARCHAR(50),
    postal_code VARCHAR(20),
    created_at TIMESTAMP DEFAULT NOW()
);

-- Departments Table
CREATE TABLE departments (
    department_id SERIAL PRIMARY KEY,
    department_name VARCHAR(100) NOT NULL,
    location_id INT REFERENCES locations(location_id),
    manager_id INT,
    budget NUMERIC(12, 2),
    created_at TIMESTAMP DEFAULT NOW()
);

-- Employees Table
CREATE TABLE employees (
    employee_id SERIAL PRIMARY KEY,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    email VARCHAR(100) UNIQUE,
    phone_number VARCHAR(20),
    hire_date DATE DEFAULT CURRENT_DATE,
    job_title VARCHAR(50),
    salary NUMERIC(10, 2),
    commission_pct NUMERIC(3, 2),
    manager_id INT REFERENCES employees(employee_id),
    department_id INT REFERENCES departments(department_id),
    status VARCHAR(20) DEFAULT 'ACTIVE',
    deleted_at TIMESTAMP,
    updated_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT NOW()
);

-- Add foreign key for department manager
ALTER TABLE departments
ADD CONSTRAINT fk_dept_manager
FOREIGN KEY (manager_id) REFERENCES employees(employee_id);

-- Customers Table  
CREATE TABLE customers (
    customer_id SERIAL PRIMARY KEY,
    customer_name VARCHAR(100) NOT NULL,
    email VARCHAR(100) UNIQUE,
    phone VARCHAR(20),
    tier VARCHAR(20) DEFAULT 'BRONZE', -- GOLD, SILVER, BRONZE
    credit_limit NUMERIC(10, 2) DEFAULT 5000,
    current_balance NUMERIC(10, 2) DEFAULT 0,
    status VARCHAR(20) DEFAULT 'ACTIVE',
    billing_day INT DEFAULT 1,
    deleted_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT NOW()
);

-- Products Table
CREATE TABLE products (
    product_id SERIAL PRIMARY KEY,
    product_name VARCHAR(100) NOT NULL,
    category_id INT,
    description TEXT,
    price NUMERIC(10, 2) NOT NULL CHECK (price >= 0),
    cost NUMERIC(10, 2),
    quantity INT DEFAULT 0,
    status VARCHAR(20) DEFAULT 'ACTIVE',
    version INT DEFAULT 0,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP
);

-- Orders Table
CREATE TABLE orders (
    order_id SERIAL PRIMARY KEY,
    order_number VARCHAR(50) UNIQUE,
    customer_id INT REFERENCES customers(customer_id),
    employee_id INT REFERENCES employees(employee_id),
    order_date DATE DEFAULT CURRENT_DATE,
    required_date DATE,
    shipped_date DATE,
    status VARCHAR(20) DEFAULT 'pending', -- pending, processing, shipped, delivered, cancelled
    total NUMERIC(10, 2) DEFAULT 0,
    order_sequence INT,
    deleted_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP
);

-- Order Items Table
CREATE TABLE order_items (
    order_item_id SERIAL PRIMARY KEY,
    order_id INT REFERENCES orders(order_id) ON DELETE CASCADE,
    product_id INT REFERENCES products(product_id),
    quantity INT NOT NULL CHECK (quantity > 0),
    unit_price NUMERIC(10, 2) NOT NULL,
    discount NUMERIC(4, 2) DEFAULT 0,
    created_at TIMESTAMP DEFAULT NOW()
);

-- Inventory Table
CREATE TABLE inventory (
    product_id INT PRIMARY KEY REFERENCES products(product_id),
    quantity INT DEFAULT 0 CHECK (quantity >= 0),
    reorder_level INT DEFAULT 10,
    warehouse_location VARCHAR(50),
    updated_at TIMESTAMP
);

-- =====================================================
-- FINANCIAL TABLES
-- =====================================================

-- Accounts Table (for transaction examples)
CREATE TABLE accounts (
    account_id SERIAL PRIMARY KEY,
    account_number VARCHAR(20) UNIQUE,
    customer_id INT REFERENCES customers(customer_id),
    account_type VARCHAR(20), -- checking, savings
    balance NUMERIC(12, 2) DEFAULT 0,
    status VARCHAR(20) DEFAULT 'ACTIVE',
    created_at TIMESTAMP DEFAULT NOW()
);

-- Sales Table (for analytics examples)
CREATE TABLE sales (
    sale_id SERIAL PRIMARY KEY,
    product_category VARCHAR(50),
    region VARCHAR(50),
    customer_segment VARCHAR(50),
    sale_date DATE,
    sale_amount NUMERIC(10, 2),
    quarter INT,
    created_at TIMESTAMP DEFAULT NOW()
);

-- Exchange Rates Table
CREATE TABLE exchange_rates (
    currency_code VARCHAR(3) PRIMARY KEY,
    rate NUMERIC(10, 6),
    updated_at TIMESTAMP DEFAULT NOW()
);

-- =====================================================
-- AUDIT AND LOGGING TABLES
-- =====================================================

-- Employee Audit Table
CREATE TABLE employee_audit (
    audit_id SERIAL PRIMARY KEY,
    employee_id INT,
    operation VARCHAR(10),
    old_values JSONB,
    new_values JSONB,
    changed_by VARCHAR(100),
    changed_at TIMESTAMP DEFAULT NOW()
);

-- Order Audit Table
CREATE TABLE order_audit (
    audit_id SERIAL PRIMARY KEY,
    order_id INT,
    operation VARCHAR(10),
    timestamp TIMESTAMP DEFAULT NOW()
);

-- Transaction Log
CREATE TABLE transaction_log (
    transaction_id SERIAL PRIMARY KEY,
    from_account INT,
    to_account INT,
    amount NUMERIC(12, 2),
    timestamp TIMESTAMP DEFAULT NOW()
);

-- Inventory Log
CREATE TABLE inventory_log (
    log_id SERIAL PRIMARY KEY,
    product_id INT,
    change_amount INT,
    timestamp TIMESTAMP DEFAULT NOW()
);

-- Error Log
CREATE TABLE error_log (
    error_id SERIAL PRIMARY KEY,
    error_message TEXT,
    error_time TIMESTAMP DEFAULT NOW()
);

-- Audit Log (general purpose)
CREATE TABLE audit_log (
    log_id SERIAL PRIMARY KEY,
    order_id INT,
    action VARCHAR(50),
    timestamp TIMESTAMP DEFAULT NOW()
);

-- =====================================================
-- SPECIALIZED TABLES
-- =====================================================

-- Bill of Materials (for recursive query example)
CREATE TABLE bill_of_materials (
    component_id VARCHAR(20),
    part_id VARCHAR(20),
    quantity INT,
    PRIMARY KEY (component_id, part_id)
);

-- Flights Table (for graph/path finding)
CREATE TABLE flights (
    flight_id SERIAL PRIMARY KEY,
    origin VARCHAR(3),
    destination VARCHAR(3),
    distance INT,
    price NUMERIC(8, 2)
);

-- Report Jobs (for async processing)
CREATE TABLE report_jobs (
    job_id SERIAL PRIMARY KEY,
    user_id INT,
    status VARCHAR(20),
    created_at TIMESTAMP DEFAULT NOW(),
    completed_at TIMESTAMP,
    result_location TEXT
);

-- Invoices Table
CREATE TABLE invoices (
    invoice_id SERIAL PRIMARY KEY,
    customer_id INT REFERENCES customers(customer_id),
    amount NUMERIC(10, 2),
    invoice_date DATE,
    due_date DATE,
    status VARCHAR(20) DEFAULT 'PENDING',
    created_at TIMESTAMP DEFAULT NOW()
);

-- Usage Charges Table
CREATE TABLE usage_charges (
    charge_id SERIAL PRIMARY KEY,
    customer_id INT REFERENCES customers(customer_id),
    amount NUMERIC(10, 2),
    charge_date DATE,
    invoiced BOOLEAN DEFAULT FALSE,
    invoice_id INT REFERENCES invoices(invoice_id)
);

-- Notification Queue
CREATE TABLE notification_queue (
    notification_id SERIAL PRIMARY KEY,
    customer_id INT,
    type VARCHAR(50),
    data JSONB,
    created_at TIMESTAMP DEFAULT NOW()
);

-- Batch Log
CREATE TABLE batch_log (
    log_id SERIAL PRIMARY KEY,
    process_name VARCHAR(100),
    execution_time TIMESTAMP,
    error_count INT DEFAULT 0
);

-- Billing Errors
CREATE TABLE billing_errors (
    error_id SERIAL PRIMARY KEY,
    customer_id INT,
    error_message TEXT,
    error_time TIMESTAMP DEFAULT NOW()
);

-- Trigger Debug Log
CREATE TABLE trigger_debug_log (
    log_id SERIAL PRIMARY KEY,
    trigger_name VARCHAR(100),
    table_name VARCHAR(100),
    operation VARCHAR(20),
    row_data JSONB,
    timestamp TIMESTAMP DEFAULT NOW()
);

-- =====================================================
-- SAMPLE DATA - LOCATIONS
-- =====================================================

INSERT INTO locations (street_address, city, state_province, country, postal_code) VALUES
('123 Main St', 'New York', 'NY', 'USA', '10001'),
('456 Market St', 'San Francisco', 'CA', 'USA', '94102'),
('789 Commerce Way', 'Chicago', 'IL', 'USA', '60601'),
('321 Tech Blvd', 'Seattle', 'WA', 'USA', '98101'),
('654 Innovation Dr', 'Austin', 'TX', 'USA', '73301'),
('147 King St', 'Toronto', 'ON', 'Canada', 'M5H 1A1'),
('258 Oxford St', 'London', '', 'UK', 'W1D 1BS'),
('369 Orchard Rd', 'Singapore', '', 'Singapore', '238874');

-- =====================================================
-- SAMPLE DATA - DEPARTMENTS
-- =====================================================

INSERT INTO departments (department_name, location_id, budget) VALUES
('Executive', 1, 500000),
('Sales', 1, 300000),
('Marketing', 2, 250000),
('Engineering', 2, 800000),
('Human Resources', 1, 150000),
('Finance', 1, 200000),
('Customer Support', 3, 180000),
('Operations', 4, 350000),
('Research & Development', 2, 600000),
('IT', 4, 400000);

-- =====================================================
-- SAMPLE DATA - EMPLOYEES
-- =====================================================

INSERT INTO employees (first_name, last_name, email, phone_number, hire_date, job_title, salary, department_id, manager_id) VALUES
-- Executive
('John', 'Smith', 'john.smith@company.com', '555-0001', '2010-01-15', 'CEO', 250000, 1, NULL),
('Sarah', 'Johnson', 'sarah.johnson@company.com', '555-0002', '2011-03-20', 'CFO', 180000, 6, 1),
('Michael', 'Williams', 'michael.williams@company.com', '555-0003', '2011-05-10', 'CTO', 200000, 4, 1),

-- Sales Department
('Emily', 'Brown', 'emily.brown@company.com', '555-0004', '2015-02-15', 'VP Sales', 140000, 2, 1),
('David', 'Jones', 'david.jones@company.com', '555-0005', '2016-07-01', 'Sales Manager', 95000, 2, 4),
('Lisa', 'Davis', 'lisa.davis@company.com', '555-0006', '2017-03-15', 'Sales Representative', 65000, 2, 5),
('James', 'Miller', 'james.miller@company.com', '555-0007', '2017-08-20', 'Sales Representative', 62000, 2, 5),
('Jennifer', 'Wilson', 'jennifer.wilson@company.com', '555-0008', '2018-01-10', 'Sales Representative', 68000, 2, 5),

-- Engineering Department
('Robert', 'Moore', 'robert.moore@company.com', '555-0009', '2012-04-01', 'VP Engineering', 160000, 4, 3),
('Patricia', 'Taylor', 'patricia.taylor@company.com', '555-0010', '2014-06-15', 'Engineering Manager', 120000, 4, 9),
('Daniel', 'Anderson', 'daniel.anderson@company.com', '555-0011', '2016-09-01', 'Senior Engineer', 110000, 4, 10),
('Mary', 'Thomas', 'mary.thomas@company.com', '555-0012', '2017-02-20', 'Software Engineer', 95000, 4, 10),
('Christopher', 'Jackson', 'christopher.jackson@company.com', '555-0013', '2018-05-15', 'Software Engineer', 92000, 4, 10),
('Jessica', 'White', 'jessica.white@company.com', '555-0014', '2019-03-01', 'Junior Engineer', 75000, 4, 10),
('Matthew', 'Harris', 'matthew.harris@company.com', '555-0015', '2019-07-10', 'Junior Engineer', 73000, 4, 10),

-- Marketing Department
('Amanda', 'Martin', 'amanda.martin@company.com', '555-0016', '2014-11-01', 'VP Marketing', 135000, 3, 1),
('Joshua', 'Thompson', 'joshua.thompson@company.com', '555-0017', '2016-01-15', 'Marketing Manager', 98000, 3, 16),
('Ashley', 'Garcia', 'ashley.garcia@company.com', '555-0018', '2018-04-01', 'Marketing Specialist', 72000, 3, 17),
('Andrew', 'Martinez', 'andrew.martinez@company.com', '555-0019', '2019-02-15', 'Marketing Specialist', 70000, 3, 17),

-- HR Department
('Stephanie', 'Robinson', 'stephanie.robinson@company.com', '555-0020', '2013-08-01', 'VP HR', 125000, 5, 1),
('Ryan', 'Clark', 'ryan.clark@company.com', '555-0021', '2016-10-15', 'HR Manager', 88000, 5, 20),
('Michelle', 'Rodriguez', 'michelle.rodriguez@company.com', '555-0022', '2018-06-01', 'HR Specialist', 65000, 5, 21),

-- Finance Department
('Kevin', 'Lewis', 'kevin.lewis@company.com', '555-0023', '2014-03-01', 'Finance Manager', 105000, 6, 2),
('Laura', 'Lee', 'laura.lee@company.com', '555-0024', '2017-09-15', 'Financial Analyst', 78000, 6, 23),
('Brian', 'Walker', 'brian.walker@company.com', '555-0025', '2019-01-10', 'Accountant', 72000, 6, 23),

-- Customer Support
('Nicole', 'Hall', 'nicole.hall@company.com', '555-0026', '2015-05-20', 'Support Manager', 82000, 7, 1),
('Jason', 'Allen', 'jason.allen@company.com', '555-0027', '2017-11-01', 'Support Specialist', 58000, 7, 26),
('Samantha', 'Young', 'samantha.young@company.com', '555-0028', '2018-08-15', 'Support Specialist', 56000, 7, 26),
('Eric', 'King', 'eric.king@company.com', '555-0029', '2019-04-20', 'Support Specialist', 55000, 7, 26),

-- Operations
('Rachel', 'Wright', 'rachel.wright@company.com', '555-0030', '2013-12-01', 'VP Operations', 145000, 8, 1),
('Justin', 'Lopez', 'justin.lopez@company.com', '555-0031', '2016-05-15', 'Operations Manager', 96000, 8, 30),

-- R&D
('Heather', 'Hill', 'heather.hill@company.com', '555-0032', '2014-07-01', 'VP R&D', 155000, 9, 1),
('Tyler', 'Scott', 'tyler.scott@company.com', '555-0033', '2017-04-10', 'Research Scientist', 105000, 9, 32),
('Rebecca', 'Green', 'rebecca.green@company.com', '555-0034', '2018-09-20', 'Research Scientist', 98000, 9, 32),

-- IT
('Brandon', 'Adams', 'brandon.adams@company.com', '555-0035', '2015-03-15', 'IT Manager', 110000, 10, 3),
('Katherine', 'Baker', 'katherine.baker@company.com', '555-0036', '2018-02-01', 'System Administrator', 82000, 10, 35),
('Jeremy', 'Nelson', 'jeremy.nelson@company.com', '555-0037', '2019-06-15', 'IT Support', 68000, 10, 35);

-- Update department managers
UPDATE departments SET manager_id = 1 WHERE department_id = 1;
UPDATE departments SET manager_id = 4 WHERE department_id = 2;
UPDATE departments SET manager_id = 16 WHERE department_id = 3;
UPDATE departments SET manager_id = 9 WHERE department_id = 4;
UPDATE departments SET manager_id = 20 WHERE department_id = 5;
UPDATE departments SET manager_id = 2 WHERE department_id = 6;
UPDATE departments SET manager_id = 26 WHERE department_id = 7;
UPDATE departments SET manager_id = 30 WHERE department_id = 8;
UPDATE departments SET manager_id = 32 WHERE department_id = 9;
UPDATE departments SET manager_id = 35 WHERE department_id = 10;

-- =====================================================
-- SAMPLE DATA - CUSTOMERS
-- =====================================================

INSERT INTO customers (customer_name, email, phone, tier, credit_limit, current_balance, billing_day) VALUES
('Acme Corporation', 'contact@acme.com', '555-1001', 'GOLD', 50000, 12000, 1),
('TechStart Inc', 'info@techstart.com', '555-1002', 'GOLD', 45000, 8500, 5),
('Global Industries', 'sales@globalind.com', '555-1003', 'GOLD', 60000, 15000, 10),
('SmallBiz LLC', 'owner@smallbiz.com', '555-1004', 'SILVER', 25000, 5000, 15),
('MediumCorp', 'purchasing@mediumcorp.com', '555-1005', 'SILVER', 30000, 7500, 20),
('StartupXYZ', 'hello@startupxyz.com', '555-1006', 'BRONZE', 10000, 2000, 1),
('Enterprise Solutions', 'contact@entsolutions.com', '555-1007', 'GOLD', 75000, 20000, 5),
('Local Shop', 'info@localshop.com', '555-1008', 'BRONZE', 8000, 1500, 10),
('Mid-Size Business', 'orders@midsizebiz.com', '555-1009', 'SILVER', 35000, 9000, 15),
('Big Enterprise', 'procurement@bigent.com', '555-1010', 'GOLD', 100000, 25000, 1),
('Small Retailer', 'contact@smallretail.com', '555-1011', 'BRONZE', 12000, 3000, 20),
('Tech Giant Partners', 'partner@techgiant.com', '555-1012', 'GOLD', 80000, 18000, 5),
('Regional Chain', 'buying@regionalchain.com', '555-1013', 'SILVER', 40000, 11000, 10),
('Online Store', 'support@onlinestore.com', '555-1014', 'SILVER', 28000, 6500, 15),
('Wholesale Distributor', 'orders@wholesale.com', '555-1015', 'GOLD', 90000, 22000, 1);

-- =====================================================
-- SAMPLE DATA - PRODUCTS
-- =====================================================

INSERT INTO products (product_name, category_id, description, price, cost, quantity) VALUES
('Laptop Pro 15"', 1, 'High-performance laptop', 1299.99, 800.00, 45),
('Desktop Workstation', 1, 'Powerful desktop computer', 1899.99, 1200.00, 28),
('Wireless Mouse', 2, 'Ergonomic wireless mouse', 29.99, 12.00, 250),
('Mechanical Keyboard', 2, 'RGB mechanical keyboard', 129.99, 65.00, 120),
('27" Monitor', 3, '4K UHD monitor', 399.99, 220.00, 75),
('USB-C Hub', 2, '7-port USB-C hub', 49.99, 18.00, 180),
('Webcam HD', 3, '1080p webcam', 79.99, 35.00, 95),
('Headset Pro', 2, 'Noise-cancelling headset', 159.99, 75.00, 110),
('External SSD 1TB', 4, 'Portable SSD drive', 139.99, 70.00, 150),
('Router Mesh', 5, 'Whole-home mesh WiFi', 299.99, 150.00, 60),
('Smart Speaker', 5, 'Voice-controlled speaker', 99.99, 45.00, 200),
('Tablet 10"', 1, 'Premium tablet', 599.99, 320.00, 85),
('Smartphone', 1, 'Latest smartphone', 899.99, 500.00, 120),
('Smartwatch', 2, 'Fitness smartwatch', 249.99, 110.00, 140),
('Wireless Charger', 2, 'Fast wireless charger', 39.99, 15.00, 300),
('Phone Case', 2, 'Protective phone case', 19.99, 5.00, 500),
('Screen Protector', 2, 'Tempered glass protector', 12.99, 3.00, 450),
('Power Bank 20000mAh', 2, 'High-capacity power bank', 49.99, 22.00, 175),
('Bluetooth Earbuds', 2, 'True wireless earbuds', 129.99, 55.00, 220),
('Laptop Bag', 2, 'Premium laptop bag', 59.99, 25.00, 160),
('Docking Station', 2, 'Universal docking station', 199.99, 95.00, 70),
('Graphics Card', 4, 'High-performance GPU', 699.99, 400.00, 35),
('RAM 16GB Kit', 4, 'DDR4 memory kit', 89.99, 45.00, 200),
('SSD 512GB', 4, 'Internal SSD', 79.99, 38.00, 180),
('Gaming Mouse', 2, 'High-DPI gaming mouse', 69.99, 30.00, 130);

-- =====================================================
-- SAMPLE DATA - ORDERS
-- =====================================================

INSERT INTO orders (customer_id, employee_id, order_date, status, total) VALUES
(1, 6, '2024-01-15', 'delivered', 2599.98),
(2, 6, '2024-01-18', 'delivered', 1899.99),
(3, 7, '2024-01-22', 'delivered', 4599.95),
(1, 6, '2024-02-05', 'delivered', 1529.97),
(4, 8, '2024-02-10', 'delivered', 759.96),
(5, 7, '2024-02-14', 'delivered', 1199.97),
(2, 6, '2024-02-20', 'delivered', 899.99),
(6, 8, '2024-03-01', 'delivered', 329.98),
(3, 7, '2024-03-05', 'delivered', 2999.94),
(7, 6, '2024-03-12', 'delivered', 5499.93),
(1, 6, '2024-03-18', 'shipped', 1799.97),
(8, 8, '2024-03-22', 'shipped', 459.98),
(4, 7, '2024-03-25', 'shipped', 999.96),
(9, 6, '2024-04-02', 'processing', 3299.95),
(5, 8, '2024-04-05', 'processing', 649.97),
(10, 7, '2024-04-08', 'processing', 7899.90),
(2, 6, '2024-04-10', 'pending', 1299.99),
(11, 8, '2024-04-12', 'pending', 529.98),
(6, 7, '2024-04-15', 'pending', 849.96),
(12, 6, '2024-04-18', 'pending', 4199.94);

-- =====================================================
-- SAMPLE DATA - ORDER ITEMS
-- =====================================================

INSERT INTO order_items (order_id, product_id, quantity, unit_price) VALUES
-- Order 1
(1, 1, 2, 1299.99),
-- Order 2
(2, 2, 1, 1899.99),
-- Order 3
(3, 1, 2, 1299.99),
(3, 5, 2, 399.99),
(3, 8, 5, 159.99),
-- Order 4
(4, 3, 10, 29.99),
(4, 4, 5, 129.99),
(4, 6, 15, 49.99),
-- Order 5
(5, 7, 10, 79.99),
-- Order 6
(6, 5, 3, 399.99),
-- Order 7
(7, 13, 1, 899.99),
-- Order 8
(8, 11, 3, 99.99),
(8, 15, 2, 39.99),
-- Order 9
(9, 1, 2, 1299.99),
(9, 5, 1, 399.99),
-- Order 10
(10, 2, 2, 1899.99),
(10, 22, 2, 699.99),
(10, 21, 3, 199.99),
-- Order 11
(11, 12, 3, 599.99),
-- Order 12
(12, 3, 5, 29.99),
(12, 16, 20, 19.99),
-- Order 13
(13, 4, 5, 129.99),
(13, 8, 2, 159.99),
-- Order 14
(14, 1, 2, 1299.99),
(14, 22, 1, 699.99),
-- Order 15
(15, 11, 5, 99.99),
(15, 15, 5, 39.99),
-- Order 16
(16, 2, 3, 1899.99),
(16, 21, 5, 199.99),
-- Order 17
(17, 1, 1, 1299.99),
-- Order 18
(18, 19, 4, 129.99),
(18, 15, 2, 39.99),
-- Order 19
(19, 12, 1, 599.99),
(19, 14, 1, 249.99),
-- Order 20
(20, 1, 2, 1299.99),
(20, 5, 2, 399.99),
(20, 8, 5, 159.99);

-- =====================================================
-- SAMPLE DATA - INVENTORY
-- =====================================================

INSERT INTO inventory (product_id, quantity, reorder_level, warehouse_location) VALUES
(1, 45, 20, 'A-101'),
(2, 28, 15, 'A-102'),
(3, 250, 100, 'B-201'),
(4, 120, 50, 'B-202'),
(5, 75, 30, 'A-103'),
(6, 180, 75, 'B-203'),
(7, 95, 40, 'C-301'),
(8, 110, 45, 'B-204'),
(9, 150, 60, 'A-104'),
(10, 60, 25, 'C-302'),
(11, 200, 80, 'C-303'),
(12, 85, 35, 'A-105'),
(13, 120, 50, 'A-106'),
(14, 140, 55, 'B-205'),
(15, 300, 120, 'B-206'),
(16, 500, 200, 'C-304'),
(17, 450, 180, 'C-305'),
(18, 175, 70, 'B-207'),
(19, 220, 90, 'B-208'),
(20, 160, 65, 'C-306'),
(21, 70, 28, 'A-107'),
(22, 35, 15, 'A-108'),
(23, 200, 80, 'B-209'),
(24, 180, 72, 'B-210'),
(25, 130, 52, 'B-211');

-- =====================================================
-- SAMPLE DATA - ACCOUNTS
-- =====================================================

INSERT INTO accounts (account_number, customer_id, account_type, balance) VALUES
('ACC-1000001', 1, 'checking', 25000.00),
('ACC-1000002', 1, 'savings', 50000.00),
('ACC-1000003', 2, 'checking', 18000.00),
('ACC-1000004', 2, 'savings', 35000.00),
('ACC-1000005', 3, 'checking', 42000.00),
('ACC-1000006', 4, 'checking', 12000.00),
('ACC-1000007', 5, 'checking', 22000.00),
('ACC-1000008', 5, 'savings', 28000.00),
('ACC-1000009', 6, 'checking', 8500.00),
('ACC-1000010', 7, 'checking', 55000.00);

-- =====================================================
-- SAMPLE DATA - SALES (for analytics)
-- =====================================================

INSERT INTO sales (product_category, region, customer_segment, sale_date, sale_amount, quarter) VALUES
('Electronics', 'North', 'Enterprise', '2024-01-15', 15000, 1),
('Electronics', 'South', 'SMB', '2024-01-20', 8500, 1),
('Electronics', 'East', 'Enterprise', '2024-01-25', 22000, 1),
('Software', 'West', 'SMB', '2024-02-10', 5500, 1),
('Software', 'North', 'Enterprise', '2024-02-15', 18000, 1),
('Hardware', 'South', 'SMB', '2024-02-20', 12000, 1),
('Electronics', 'East', 'Enterprise', '2024-03-05', 28000, 1),
('Software', 'West', 'SMB', '2024-03-10', 7200, 1),
('Hardware', 'North', 'Enterprise', '2024-03-15', 19500, 1),
('Electronics', 'South', 'SMB', '2024-04-02', 9800, 2),
('Software', 'East', 'Enterprise', '2024-04-08', 24000, 2),
('Hardware', 'West', 'SMB', '2024-04-12', 11000, 2),
('Electronics', 'North', 'Enterprise', '2024-05-05', 32000, 2),
('Software', 'South', 'SMB', '2024-05-10', 6700, 2),
('Hardware', 'East', 'Enterprise', '2024-05-18', 21500, 2),
('Electronics', 'West', 'SMB', '2024-06-03', 14200, 2),
('Software', 'North', 'Enterprise', '2024-06-15', 27000, 2),
('Hardware', 'South', 'SMB', '2024-06-22', 13500, 2);

-- =====================================================
-- SAMPLE DATA - EXCHANGE RATES
-- =====================================================

INSERT INTO exchange_rates (currency_code, rate) VALUES
('USD', 1.000000),
('EUR', 0.850000),
('GBP', 0.730000),
('JPY', 110.500000),
('CAD', 1.250000),
('AUD', 1.350000),
('CHF', 0.920000),
('CNY', 6.450000);

-- =====================================================
-- SAMPLE DATA - BILL OF MATERIALS
-- =====================================================

INSERT INTO bill_of_materials (component_id, part_id, quantity) VALUES
('LAPTOP-PRO', 'SCREEN-15', 1),
('LAPTOP-PRO', 'KEYBOARD', 1),
('LAPTOP-PRO', 'MOTHERBOARD', 1),
('MOTHERBOARD', 'CPU', 1),
('MOTHERBOARD', 'RAM-SLOT', 2),
('MOTHERBOARD', 'SSD-SLOT', 1),
('KEYBOARD', 'KEY-SWITCH', 85),
('KEYBOARD', 'PCB', 1),
('SCREEN-15', 'LCD-PANEL', 1),
('SCREEN-15', 'BEZEL', 1);

-- =====================================================
-- SAMPLE DATA - FLIGHTS
-- =====================================================

INSERT INTO flights (origin, destination, distance, price) VALUES
('SFO', 'LAX', 337, 150),
('SFO', 'SEA', 679, 200),
('SFO', 'DEN', 967, 250),
('LAX', 'DEN', 862, 220),
('LAX', 'PHX', 370, 160),
('SEA', 'DEN', 1024, 270),
('DEN', 'ORD', 888, 240),
('DEN', 'DFW', 641, 210),
('ORD', 'JFK', 740, 230),
('DFW', 'JFK', 1391, 320),
('PHX', 'DFW', 868, 240),
('SEA', 'SFO', 679, 200);

-- =====================================================
-- INDEXES FOR PERFORMANCE
-- =====================================================

-- Employee indexes
CREATE INDEX idx_employees_dept ON employees(department_id);
CREATE INDEX idx_employees_manager ON employees(manager_id);
CREATE INDEX idx_employees_salary ON employees(salary);
CREATE INDEX idx_employees_status ON employees(status) WHERE status = 'ACTIVE';
CREATE INDEX idx_employees_email ON employees(LOWER(email));

-- Order indexes
CREATE INDEX idx_orders_customer ON orders(customer_id);
CREATE INDEX idx_orders_employee ON orders(employee_id);
CREATE INDEX idx_orders_date ON orders(order_date);
CREATE INDEX idx_orders_status ON orders(status);

-- Order items indexes
CREATE INDEX idx_order_items_order ON order_items(order_id);
CREATE INDEX idx_order_items_product ON order_items(product_id);

-- Product indexes
CREATE INDEX idx_products_category ON products(category_id);
CREATE INDEX idx_products_price ON products(price);

-- Customer indexes
CREATE INDEX idx_customers_tier ON customers(tier);
CREATE INDEX idx_customers_status ON customers(status);

-- Account indexes
CREATE INDEX idx_accounts_customer ON accounts(customer_id);
CREATE INDEX idx_accounts_number ON accounts(account_number);

-- Sales indexes
CREATE INDEX idx_sales_date ON sales(sale_date);
CREATE INDEX idx_sales_region ON sales(region);
CREATE INDEX idx_sales_category ON sales(product_category);

-- =====================================================
-- VIEWS
-- =====================================================

-- Employee hierarchy view
CREATE OR REPLACE VIEW employee_hierarchy_view AS
SELECT 
    e.employee_id,
    e.first_name || ' ' || e.last_name as employee_name,
    e.job_title,
    e.department_id,
    d.department_name,
    m.first_name || ' ' || m.last_name as manager_name
FROM employees e
LEFT JOIN employees m ON e.manager_id = m.employee_id
LEFT JOIN departments d ON e.department_id = d.department_id
WHERE e.status = 'ACTIVE';

-- Department statistics view
CREATE OR REPLACE VIEW department_stats AS
SELECT 
    d.department_id,
    d.department_name,
    COUNT(e.employee_id) as employee_count,
    AVG(e.salary) as avg_salary,
    MIN(e.salary) as min_salary,
    MAX(e.salary) as max_salary,
    SUM(e.salary) as total_payroll
FROM departments d
LEFT JOIN employees e ON d.department_id = e.department_id AND e.status = 'ACTIVE'
GROUP BY d.department_id, d.department_name;

-- Order summary view
CREATE OR REPLACE VIEW order_summary AS
SELECT 
    o.order_id,
    o.order_date,
    c.customer_name,
    e.first_name || ' ' || e.last_name as sales_rep,
    o.status,
    COUNT(oi.order_item_id) as item_count,
    SUM(oi.quantity * oi.unit_price) as calculated_total,
    o.total as order_total
FROM orders o
JOIN customers c ON o.customer_id = c.customer_id
LEFT JOIN employees e ON o.employee_id = e.employee_id
LEFT JOIN order_items oi ON o.order_id = oi.order_id
GROUP BY o.order_id, o.order_date, c.customer_name, e.first_name, e.last_name, o.status, o.total;

-- =====================================================
-- USEFUL QUERIES TO GET STARTED
-- =====================================================

/*
-- View all employees with their departments
SELECT * FROM employee_hierarchy_view;

-- View department statistics
SELECT * FROM department_stats ORDER BY employee_count DESC;

-- View recent orders
SELECT * FROM order_summary ORDER BY order_date DESC LIMIT 10;

-- Find top selling products
SELECT 
    p.product_name,
    SUM(oi.quantity) as units_sold,
    SUM(oi.quantity * oi.unit_price) as revenue
FROM order_items oi
JOIN products p ON oi.product_id = p.product_id
GROUP BY p.product_id, p.product_name
ORDER BY revenue DESC
LIMIT 10;

-- Employee salary rankings within departments
SELECT 
    first_name,
    last_name,
    department_id,
    salary,
    RANK() OVER (PARTITION BY department_id ORDER BY salary DESC) as dept_rank
FROM employees
WHERE status = 'ACTIVE';

-- Monthly sales trend
SELECT 
    DATE_TRUNC('month', order_date) as month,
    COUNT(*) as order_count,
    SUM(total) as monthly_revenue
FROM orders
GROUP BY DATE_TRUNC('month', order_date)
ORDER BY month;
*/

-- =====================================================
-- COMPLETION MESSAGE
-- =====================================================

SELECT 'Database setup completed successfully!' as message,
       (SELECT COUNT(*) FROM employees) as employee_count,
       (SELECT COUNT(*) FROM customers) as customer_count,
       (SELECT COUNT(*) FROM products) as product_count,
       (SELECT COUNT(*) FROM orders) as order_count;
