-- ============================================================================
-- Project: E-Commerce Performance Tuning Lab
-- Step: 02 - Baseline 3NF Relational Schema (No Secondary Indexes)
-- Description: Core transactional schema. Only Primary Keys have indexes.
-- ============================================================================

-- 1. Create a dedicated database and schema (run database creation separately if needed)
-- CREATE DATABASE ecommerce_perf_lab;
-- \c ecommerce_perf_lab;

CREATE SCHEMA IF NOT EXISTS core_oltp;
SET search_path TO core_oltp, public;

-- Drop existing tables if re-running
DROP TABLE IF EXISTS order_items CASCADE;
DROP TABLE IF EXISTS orders CASCADE;
DROP TABLE IF EXISTS products CASCADE;
DROP TABLE IF EXISTS users CASCADE;

-- ============================================================================
-- Table: users
-- Represents registered customer profiles.
-- ============================================================================
CREATE TABLE users (
    user_id BIGSERIAL PRIMARY KEY,
    email VARCHAR(255) NOT NULL,
    full_name VARCHAR(150) NOT NULL,
    phone_number VARCHAR(30),
    country_code CHAR(2) NOT NULL DEFAULT 'IN',
    city VARCHAR(100) NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CLOCK_TIMESTAMP(),
    is_active BOOLEAN NOT NULL DEFAULT TRUE
);

-- ============================================================================
-- Table: products
-- Product catalog with inventory counts for concurrency testing.
-- ============================================================================
CREATE TABLE products (
    product_id BIGSERIAL PRIMARY KEY,
    sku VARCHAR(64) NOT NULL,
    name VARCHAR(255) NOT NULL,
    category VARCHAR(80) NOT NULL,
    price NUMERIC(10, 2) NOT NULL CHECK (price >= 0),
    stock_quantity INT NOT NULL CHECK (stock_quantity >= 0),
    created_at TIMESTAMPTZ NOT NULL DEFAULT CLOCK_TIMESTAMP()
);

-- ============================================================================
-- Table: orders
-- Transaction headers. Foreign keys are enforced, but NOT indexed.
-- ============================================================================
CREATE TABLE orders (
    order_id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL REFERENCES users(user_id) ON DELETE RESTRICT,
    status VARCHAR(32) NOT NULL CHECK (status IN ('PENDING', 'PROCESSING', 'COMPLETED', 'CANCELLED', 'REFUNDED')),
    total_amount NUMERIC(12, 2) NOT NULL DEFAULT 0.00,
    shipping_address TEXT NOT NULL,
    order_date TIMESTAMPTZ NOT NULL DEFAULT CLOCK_TIMESTAMP()
);

-- ============================================================================
-- Table: order_items
-- Transaction line items. High-volume junction table linking orders to products.
-- ============================================================================
CREATE TABLE order_items (
    item_id BIGSERIAL PRIMARY KEY,
    order_id BIGINT NOT NULL REFERENCES orders(order_id) ON DELETE CASCADE,
    product_id BIGINT NOT NULL REFERENCES products(product_id) ON DELETE RESTRICT,
    quantity INT NOT NULL CHECK (quantity > 0),
    unit_price NUMERIC(10, 2) NOT NULL CHECK (unit_price >= 0),
    discount_amount NUMERIC(10, 2) NOT NULL DEFAULT 0.00 CHECK (discount_amount >= 0)
);

-- Reset autovacuum to default parameters for baseline testing
ALTER TABLE orders RESET (autovacuum_vacuum_scale_factor, autovacuum_vacuum_cost_limit);
ALTER TABLE order_items RESET (autovacuum_vacuum_scale_factor, autovacuum_vacuum_cost_limit);