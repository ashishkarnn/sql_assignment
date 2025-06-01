-- 1. Create employees table with constraints
CREATE TABLE employees (
    emp_id INT NOT NULL PRIMARY KEY,
    emp_name VARCHAR(100) NOT NULL,
    age INT CHECK (age >= 18),  -- Works only in MySQL 8.0+
    email VARCHAR(100) UNIQUE,
    salary DECIMAL(10, 2) DEFAULT 30000.00
);

-- 2. Descriptive answer (write in comments or a text note):
-- Constraints help maintain data integrity and enforce rules like uniqueness, non-null values, and valid ranges.

-- 3. Descriptive answer:
-- NOT NULL ensures that a column must always have a value; it prevents missing (NULL) entries.

-- 4. Add/Remove constraints example (assuming products table exists)
ALTER TABLE products ADD CONSTRAINT pk_product PRIMARY KEY (product_id);
ALTER TABLE products DROP PRIMARY KEY;

-- 5. Descriptive answer:
-- A constraint violation example is inserting a duplicate email into the employees table, which violates the UNIQUE constraint.

-- 6. Modify products table (product_id and price columns must exist)
ALTER TABLE products ADD PRIMARY KEY (product_id);
ALTER TABLE products ALTER COLUMN price SET DEFAULT 50.00;

-- 7. INNER JOIN between student and class tables
SELECT student.student_name, class.class_name
FROM student
INNER JOIN class ON student.class_id = class.class_id;

-- 8. List products with or without orders
SELECT o.order_id, c.customer_name, p.product_name
FROM product p
LEFT JOIN order_items oi ON p.product_id = oi.product_id
LEFT JOIN orders o ON oi.order_id = o.order_id
LEFT JOIN customer c ON o.customer_id = c.customer_id;

-- 9. Total sales per product
SELECT p.product_name, SUM(oi.quantity * oi.unit_price) AS total_sales
FROM product p
INNER JOIN order_items oi ON p.product_id = oi.product_id
GROUP BY p.product_name;

-- 10. Order details with quantity
SELECT o.order_id, c.customer_name, oi.quantity
FROM orders o
INNER JOIN customer c ON o.customer_id = c.customer_id
INNER JOIN order_items oi ON o.order_id = oi.order_id;
