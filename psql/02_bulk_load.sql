-- ============================================================================
-- Step 4: High-Throughput Bulk Data Ingestion & Statistics Collection
-- ============================================================================

-- If you created tables in the core_oltp schema, set search path first:
SET search_path TO core_oltp, public;
-- Wipe all existing rows and restart identity sequences
TRUNCATE TABLE order_items, orders, products, users RESTART IDENTITY CASCADE;

-- 1. Ingest users (~100,000 rows)
\copy users(user_id, email, full_name, phone_number, country_code, city, created_at, is_active) FROM 'data_exports/users.csv' WITH (FORMAT csv, HEADER true, ENCODING 'utf-8');

-- 2. Ingest products (~20,000 rows)
\copy products(product_id, sku, name, category, price, stock_quantity, created_at) FROM 'data_exports/products.csv' WITH (FORMAT csv, HEADER true, ENCODING 'utf-8');

-- 3. Ingest orders (~5,000,000 rows)
\copy orders(order_id, user_id, status, total_amount, shipping_address, order_date) FROM 'data_exports/orders.csv' WITH (FORMAT csv, HEADER true, ENCODING 'utf-8');

-- 4. Ingest order_items (~12,500,000 rows)
\copy order_items(item_id, order_id, product_id, quantity, unit_price, discount_amount) FROM 'data_exports/order_items.csv' WITH (FORMAT csv, HEADER true, ENCODING 'utf-8');

-- ============================================================================
-- Sync Primary Key Sequences
-- Because explicit IDs were imported from CSV, advance sequences past max(id)
-- ============================================================================
SELECT setval(pg_get_serial_sequence('users', 'user_id'), COALESCE(MAX(user_id), 1)) FROM users;
SELECT setval(pg_get_serial_sequence('products', 'product_id'), COALESCE(MAX(product_id), 1)) FROM products;
SELECT setval(pg_get_serial_sequence('orders', 'order_id'), COALESCE(MAX(order_id), 1)) FROM orders;
SELECT setval(pg_get_serial_sequence('order_items', 'item_id'), COALESCE(MAX(item_id), 1)) FROM order_items;

-- ============================================================================
-- Compute Optimizer Statistics
-- Updates pg_statistic / pg_class so query planner knows table distribution
-- ============================================================================
VACUUM ANALYZE users;
VACUUM ANALYZE products;
VACUUM ANALYZE orders;
VACUUM ANALYZE order_items;