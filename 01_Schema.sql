-- ============================================================
-- E-Commerce Sales & Customer Analytics Project
-- Database Schema (SQLite / MySQL / PostgreSQL compatible)
-- ============================================================

-- Drop tables if exist (for clean re-run)
DROP TABLE IF EXISTS order_items;
DROP TABLE IF EXISTS orders;
DROP TABLE IF EXISTS products;
DROP TABLE IF EXISTS customers;

-- ============================================================
-- 1. CUSTOMERS TABLE
-- ============================================================
CREATE TABLE customers (
    customer_id   VARCHAR(20) PRIMARY KEY,
    customer_name VARCHAR(100) NOT NULL,
    email         VARCHAR(150),
    city          VARCHAR(50),
    state         VARCHAR(50),
    segment       VARCHAR(20),          -- Premium / Regular / Budget
    join_date     DATE
);

-- ============================================================
-- 2. PRODUCTS TABLE
-- ============================================================
CREATE TABLE products (
    product_id   VARCHAR(20) PRIMARY KEY,
    product_name VARCHAR(100) NOT NULL,
    category     VARCHAR(50),
    sub_category VARCHAR(50),
    unit_price   DECIMAL(10,2),
    cost_price   DECIMAL(10,2)
);

-- ============================================================
-- 3. ORDERS TABLE
-- ============================================================
CREATE TABLE orders (
    order_id       VARCHAR(20) PRIMARY KEY,
    customer_id    VARCHAR(20),
    order_date     DATE,
    status         VARCHAR(20),         -- Delivered / Shipped / Cancelled / Returned
    payment_method VARCHAR(30),
    shipping_city  VARCHAR(50),
    FOREIGN KEY (customer_id) REFERENCES customers(customer_id)
);

-- ============================================================
-- 4. ORDER_ITEMS TABLE (Fact table)
-- ============================================================
CREATE TABLE order_items (
    order_item_id VARCHAR(20) PRIMARY KEY,
    order_id      VARCHAR(20),
    product_id    VARCHAR(20),
    quantity      INTEGER,
    unit_price    DECIMAL(10,2),
    discount_pct  DECIMAL(5,2),
    line_total    DECIMAL(12,2),
    FOREIGN KEY (order_id) REFERENCES orders(order_id),
    FOREIGN KEY (product_id) REFERENCES products(product_id)
);

-- ============================================================
-- Indexes for performance (good to mention in interview)
-- ============================================================
CREATE INDEX idx_orders_customer ON orders(customer_id);
CREATE INDEX idx_orders_date ON orders(order_date);
CREATE INDEX idx_order_items_order ON order_items(order_id);
CREATE INDEX idx_order_items_product ON order_items(product_id);
