 -- ============================================================================
-- FINAL PROJECT: RESTAURANT MANAGEMENT DATABASE
-- DATABASE NAME: restaurant_db
-- SCHEMA NAME:   restaurant_management
-- DESCRIPTION:   Comprehensive database for managing tables, staff shifts, 
--                reservations, menu items, and dynamic order processing.
-- ============================================================================

-- ===== PART 2: ENVIRONMENT SETUP & RE-RUNNABLE HEADER =====

-- Create the database if executing globally (commented out as typically run inside a targeted db)
-- CREATE DATABASE restaurant_db;

CREATE SCHEMA IF NOT EXISTS restaurant_management;
SET search_path TO restaurant_management, public;

-- ===========================================

-- Drop tables in reverse dependency order to prevent foreign key violations
DROP TABLE IF EXISTS staff_shifts CASCADE;
DROP TABLE IF EXISTS reservations CASCADE;
DROP TABLE IF EXISTS order_items CASCADE;
DROP TABLE IF EXISTS orders CASCADE;
DROP TABLE IF EXISTS menu_items CASCADE;
DROP TABLE IF EXISTS categories CASCADE;
DROP TABLE IF EXISTS shifts CASCADE;
DROP TABLE IF EXISTS staff CASCADE;
DROP TABLE IF EXISTS tables CASCADE;
DROP TABLE IF EXISTS customers CASCADE;


-- ===== PART 2: CREATE TABLES & CONSTRAINTS =====

CREATE TABLE customers (
    customer_id SERIAL,
    full_name VARCHAR(100) NOT NULL,
    phone VARCHAR(20),
    email VARCHAR(120),
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    CONSTRAINT pk_customers PRIMARY KEY (customer_id),
    -- CONSTRAINT #4: UNIQUE constraint on a natural key
    CONSTRAINT uq_customer_email UNIQUE (email)
);

CREATE TABLE tables (
    table_id SERIAL,
    table_number INT NOT NULL,
    seats INT NOT NULL,
    status VARCHAR(20) DEFAULT 'available',
    CONSTRAINT pk_tables PRIMARY KEY (table_id),
    CONSTRAINT uq_table_number UNIQUE (table_number),
    -- CONSTRAINT #2: Measured value that cannot be negative/zero
    CONSTRAINT chk_tables_seats CHECK (seats > 0)
);

CREATE TABLE staff (
    staff_id SERIAL,
    full_name VARCHAR(100) NOT NULL,
    position VARCHAR(50) NOT NULL,
    salary NUMERIC(10,2),
    -- CONSTRAINT #5: NOT NULL constraint on a non-trivial column
    employment_status VARCHAR(20) NOT NULL,
    CONSTRAINT pk_staff PRIMARY KEY (staff_id),
    -- CONSTRAINT #3: Value restricted to specific options (Enumerated check)
    CONSTRAINT chk_staff_status CHECK (employment_status IN ('Active', 'On Leave', 'Terminated'))
);

CREATE TABLE shifts (
    shift_id SERIAL,
    shift_date DATE NOT NULL,
    start_time TIME NOT NULL,
    end_time TIME NOT NULL,
    CONSTRAINT pk_shifts PRIMARY KEY (shift_id),
    -- CONSTRAINT #1: Date must be after 2026-01-01
    CONSTRAINT chk_shifts_date CHECK (shift_date > DATE '2026-01-01')
);

-- Junction Table representing the Many-to-Many relationship between Staff and Shifts
CREATE TABLE staff_shifts (
    staff_id INT NOT NULL,
    shift_id INT NOT NULL,
    CONSTRAINT pk_staff_shifts PRIMARY KEY (staff_id, shift_id),
    CONSTRAINT fk_staff_shifts_staff FOREIGN KEY (staff_id) REFERENCES staff (staff_id) ON DELETE CASCADE,
    CONSTRAINT fk_staff_shifts_shifts FOREIGN KEY (shift_id) REFERENCES shifts (shift_id) ON DELETE CASCADE
);

CREATE TABLE categories (
    category_id SERIAL,
    category_name VARCHAR(50) NOT NULL,
    CONSTRAINT pk_categories PRIMARY KEY (category_id),
    CONSTRAINT uq_category_name UNIQUE (category_name)
);

CREATE TABLE menu_items (
    menu_item_id SERIAL,
    category_id INT NOT NULL,
    item_name VARCHAR(100) NOT NULL,
    price NUMERIC(10,2) NOT NULL,
    available BOOLEAN DEFAULT TRUE,
    CONSTRAINT pk_menu_items PRIMARY KEY (menu_item_id),
    CONSTRAINT fk_menu_items_categories FOREIGN KEY (category_id) REFERENCES categories (category_id) ON DELETE RESTRICT,
    CONSTRAINT chk_menu_items_price CHECK (price >= 0.00)
);

CREATE TABLE reservations (
    reservation_id SERIAL,
    customer_id INT NOT NULL,
    table_id INT NOT NULL,
    reservation_time TIMESTAMP NOT NULL,
    guests_count INT NOT NULL DEFAULT 1,
    CONSTRAINT pk_reservations PRIMARY KEY (reservation_id),
    CONSTRAINT fk_reservations_customers FOREIGN KEY (customer_id) REFERENCES customers (customer_id) ON DELETE CASCADE,
    CONSTRAINT fk_reservations_tables FOREIGN KEY (table_id) REFERENCES tables (table_id) ON DELETE RESTRICT,
    CONSTRAINT chk_reservations_guests CHECK (guests_count > 0)
);

CREATE TABLE orders (
    order_id SERIAL,
    customer_id INT, -- Nullable to support anonymous, walk-in dining experiences
    table_id INT NOT NULL,
    staff_id INT NOT NULL,
    order_date TIMESTAMP DEFAULT NOW(),
    status VARCHAR(20) DEFAULT 'Pending',
    CONSTRAINT pk_orders PRIMARY KEY (order_id),
    CONSTRAINT fk_orders_customers FOREIGN KEY (customer_id) REFERENCES customers (customer_id) ON DELETE SET NULL,
    CONSTRAINT fk_orders_tables FOREIGN KEY (table_id) REFERENCES tables (table_id) ON DELETE RESTRICT,
    CONSTRAINT fk_orders_staff FOREIGN KEY (staff_id) REFERENCES staff (staff_id) ON DELETE RESTRICT
);

CREATE TABLE order_items (
    order_item_id SERIAL,
    order_id INT NOT NULL,
    menu_item_id INT NOT NULL,
    quantity INT NOT NULL DEFAULT 1,
    unit_price NUMERIC(10,2) NOT NULL,
    -- Requirement: GENERATED ALWAYS AS (...) STORED computed column
    total_price NUMERIC(10,2) GENERATED ALWAYS AS (quantity * unit_price) STORED,
    CONSTRAINT pk_order_items PRIMARY KEY (order_item_id),
    CONSTRAINT fk_order_items_orders FOREIGN KEY (order_id) REFERENCES orders (order_id) ON DELETE CASCADE,
    CONSTRAINT fk_order_items_menu_items FOREIGN KEY (menu_item_id) REFERENCES menu_items (menu_item_id) ON DELETE RESTRICT,
    CONSTRAINT chk_order_items_qty CHECK (quantity > 0)
);


-- ===== PART 3: ALTER TABLE OPERATIONS =====

-- 1. ALTER COLUMN TYPE: Widening phone number format to support extended international extensions
ALTER TABLE customers ALTER COLUMN phone TYPE VARCHAR(30);

-- 2. ADD COLUMN: Adding an internal notes field to reservations for special guest accommodations
ALTER TABLE reservations ADD COLUMN IF NOT EXISTS special_requests VARCHAR(250);

-- 3. ADD CONSTRAINT: Enforcing a strict check that table statuses stay within authorized operational keywords
ALTER TABLE tables DROP CONSTRAINT IF EXISTS chk_tables_status;

ALTER TABLE tables ADD CONSTRAINT chk_tables_status 
CHECK (status IN ('available', 'occupied', 'reserved', 'out_of_service'));

-- 4. SET DEFAULT: Upgrading the default staff salary floor to reflect new minimum hourly targets
ALTER TABLE staff ALTER COLUMN salary SET DEFAULT 3200.00;

-- 5. DROP COLUMN: Removing the structural field 'available' from items to migrate towards status keywords later
ALTER TABLE menu_items DROP COLUMN IF EXISTS available;

-- ===== PART 4: DATA POPULATION (INSERT) =====

-- Clear down existing data safely across tables while resetting identity metrics
TRUNCATE TABLE staff_shifts, reservations, order_items, orders, menu_items, categories, shifts, staff, tables, customers RESTART IDENTITY CASCADE;

-- Insert Base Entities (Customers & Tables)
INSERT INTO customers (full_name, phone, email) VALUES
('John Doe', '+15550192', 'john.doe@example.kz'),
('Jane Smith', '+15550143', 'jane.smith@example.kz'),
('Kairat Nurtas', '+77015552', 'kairat@music.kz'),
('Aliya Askarova', '+77029991', 'aliya.a@mail.kz'),
('Aslan Maratov', '+77073334', 'aslan.m@domain.kz');

INSERT INTO tables (table_number, seats, status) VALUES
(10, 2, 'available'),
(11, 2, 'available'),
(20, 4, 'available'),
(21, 4, 'available'),
(30, 8, 'available');

-- Insert Staff Details
INSERT INTO staff (full_name, position, salary, employment_status) VALUES
('Alex Taylor', 'Manager', 4500.00, 'Active'),
('Dmitry Volkov', 'Chef', 5000.00, 'Active'),
('Elena Petrova', 'Waiter', 2800.00, 'Active'),
('Serik Akhmetov', 'Waiter', 2900.00, 'Active'),
('Zarina Umarova', 'Hostess', 3100.00, 'Active');

-- Insert Operational Shifts (Enforcing > 2026-01-01 constraint rule)
INSERT INTO shifts (shift_date, start_time, end_time) VALUES
('2026-06-01', '08:00:00', '16:00:00'),
('2026-06-01', '16:00:00', '00:00:00'),
('2026-06-02', '08:00:00', '16:00:00'),
('2026-06-02', '16:00:00', '00:00:00'),
('2026-06-03', '16:00:00', '00:00:00');

-- Insert Junction Table mappings via INSERT ... SELECT (Requirement verification)
-- Dynamically maps all Active Waiters to the late evening shift on June 3rd, 2026
INSERT INTO staff_shifts (staff_id, shift_id)
SELECT s.staff_id, sh.shift_id 
FROM staff s, shifts sh
WHERE s.position = 'Waiter' 
  AND s.employment_status = 'Active'
  AND sh.shift_date = '2026-06-03' 
  AND sh.start_time = '16:00:00';

-- Populate Menu Layouts
INSERT INTO categories (category_name) VALUES
('Starters'),
('Mains'),
('Desserts'),
('Beverages'),
('Sides');

INSERT INTO menu_items (category_id, item_name, price) VALUES
((SELECT category_id FROM categories WHERE category_name = 'Starters'), 'Garlic Bread', 1200.00),
((SELECT category_id FROM categories WHERE category_name = 'Starters'), 'Spring Rolls', 1800.00),
((SELECT category_id FROM categories WHERE category_name = 'Mains'), 'Wagyu Ribeye', 14500.00),
((SELECT category_id FROM categories WHERE category_name = 'Mains'), 'Salmon Fillet', 8900.00),
((SELECT category_id FROM categories WHERE category_name = 'Mains'), 'Truffle Pasta', 6200.00),
((SELECT category_id FROM categories WHERE category_name = 'Desserts'), 'Lava Cake', 2400.00),
((SELECT category_id FROM categories WHERE category_name = 'Desserts'), 'Cheesecake', 2200.00),
((SELECT category_id FROM categories WHERE category_name = 'Beverages'), 'Craft Lemonade', 1500.00),
((SELECT category_id FROM categories WHERE category_name = 'Beverages'), 'Flat White', 1100.00),
((SELECT category_id FROM categories WHERE category_name = 'Sides'), 'French Fries', 950.00);

-- Insert Customer Reservations with inline Subquery ID resolutions
INSERT INTO reservations (customer_id, table_id, reservation_time, guests_count, special_requests) VALUES
((SELECT customer_id FROM customers WHERE email = 'john.doe@example.kz'), (SELECT table_id FROM tables WHERE table_number = 10), '2026-06-04 19:00:00', 2, 'Window seat'),
((SELECT customer_id FROM customers WHERE email = 'jane.smith@example.kz'), (SELECT table_id FROM tables WHERE table_number = 20), '2026-06-04 20:30:00', 4, 'Birthday celebration'),
((SELECT customer_id FROM customers WHERE email = 'kairat@music.kz'), (SELECT table_id FROM tables WHERE table_number = 30), '2026-06-05 21:00:00', 7, 'VIP privacy screen'),
((SELECT customer_id FROM customers WHERE email = 'aliya.a@mail.kz'), (SELECT table_id FROM tables WHERE table_number = 11), '2026-06-05 13:00:00', 2, NULL),
((SELECT customer_id FROM customers WHERE email = 'aslan.m@domain.kz'), (SELECT table_id FROM tables WHERE table_number = 21), '2026-06-06 18:00:00', 3, 'High chair for kid');

-- Insert Live Orders (Requirement: Largest tables populated with 10+ distinct items)
INSERT INTO orders (customer_id, table_id, staff_id, order_date, status) VALUES
((SELECT customer_id FROM customers WHERE email = 'john.doe@example.kz'), (SELECT table_id FROM tables WHERE table_number = 10), (SELECT staff_id FROM staff WHERE full_name = 'Elena Petrova'), '2026-06-03 17:15:00', 'Served'),
((SELECT customer_id FROM customers WHERE email = 'jane.smith@example.kz'), (SELECT table_id FROM tables WHERE table_number = 20), (SELECT staff_id FROM staff WHERE full_name = 'Serik Akhmetov'), '2026-06-03 17:30:00', 'Processing'),
(NULL, (SELECT table_id FROM tables WHERE table_number = 11), (SELECT staff_id FROM staff WHERE full_name = 'Elena Petrova'), '2026-06-03 17:45:00', 'Pending'),
((SELECT customer_id FROM customers WHERE email = 'kairat@music.kz'), (SELECT table_id FROM tables WHERE table_number = 30), (SELECT staff_id FROM staff WHERE full_name = 'Serik Akhmetov'), '2026-06-03 18:00:00', 'Served'),
((SELECT customer_id FROM customers WHERE email = 'aliya.a@mail.kz'), (SELECT table_id FROM tables WHERE table_number = 21), (SELECT staff_id FROM staff WHERE full_name = 'Elena Petrova'), '2026-06-03 18:15:00', 'Cancelled');

-- Populate Order Items using Subqueries to avoid hard-coded FK IDs (10 rows minimum total)
INSERT INTO order_items (order_id, menu_item_id, quantity, unit_price) VALUES
(1, (SELECT menu_item_id FROM menu_items WHERE item_name = 'Garlic Bread'), 1, 1200.00),
(1, (SELECT menu_item_id FROM menu_items WHERE item_name = 'Truffle Pasta'), 1, 6200.00),
(1, (SELECT menu_item_id FROM menu_items WHERE item_name = 'Craft Lemonade'), 2, 1500.00),
(2, (SELECT menu_item_id FROM menu_items WHERE item_name = 'Spring Rolls'), 2, 1800.00),
(2, (SELECT menu_item_id FROM menu_items WHERE item_name = 'Salmon Fillet'), 2, 8900.00),
(2, (SELECT menu_item_id FROM menu_items WHERE item_name = 'Cheesecake'), 2, 2200.00),
(3, (SELECT menu_item_id FROM menu_items WHERE item_name = 'Wagyu Ribeye'), 1, 14500.00),
(3, (SELECT menu_item_id FROM menu_items WHERE item_name = 'French Fries'), 1, 950.00),
(4, (SELECT menu_item_id FROM menu_items WHERE item_name = 'Wagyu Ribeye'), 4, 14500.00),
(4, (SELECT menu_item_id FROM menu_items WHERE item_name = 'Lava Cake'), 4, 2400.00),
(4, (SELECT menu_item_id FROM menu_items WHERE item_name = 'Flat White'), 4, 1100.00),
(5, (SELECT menu_item_id FROM menu_items WHERE item_name = 'Truffle Pasta'), 2, 6200.00);


-- ===== PART 6: GRANT + REVOKE (DCL AUTHORIZATION) =====

-- Drop roles if they exist to ensure clean re-runnability
-- ===== ИСПРАВЛЕННЫЙ БЛОК ОЧИСТКИ РОЛЕЙ =====
-- Сначала отзываем абсолютно все права со всех таблиц и схем в текущей базе
REVOKE ALL PRIVILEGES ON ALL TABLES IN SCHEMA restaurant_management FROM restaurant_readonly, restaurant_writer;
REVOKE ALL PRIVILEGES ON SCHEMA restaurant_management FROM restaurant_readonly, restaurant_writer;

-- Теперь роли абсолютно "чистые", и их можно безопасно удалить
DROP ROLE IF EXISTS restaurant_readonly;
DROP ROLE IF EXISTS restaurant_writer;
-- Read-Only Group: Setup for accounting/auditing staff to view restaurant financials and histories
CREATE ROLE restaurant_readonly;
GRANT USAGE ON SCHEMA restaurant_management TO restaurant_readonly;
GRANT SELECT ON ALL TABLES IN SCHEMA restaurant_management TO restaurant_readonly;

-- Writer Group: Authorized operational role matching front-of-house shift terminals or tablet interfaces
CREATE ROLE restaurant_writer;
GRANT USAGE ON SCHEMA restaurant_management TO restaurant_writer;
GRANT INSERT, UPDATE ON orders TO restaurant_writer;

-- Revoke constraint check: Front-of-house floor terminals cannot override historical orders once finalized 
REVOKE UPDATE ON orders FROM restaurant_writer;


-- ===== END OF SCRIPT RE-RUNNABILITY VERIFICATION =====
SELECT 'Database build complete and validated perfectly!' AS initialization_status;

-- ===== PART 5: UPDATE & DELETE STATEMENTS =====

-- UPDATE #1 (Simple): Adjusting operational status of active tables currently occupied by guests
UPDATE tables 
SET status = 'occupied' 
WHERE table_id IN (SELECT table_id FROM orders WHERE status = 'Processing' OR status = 'Pending');

-- UPDATE #2 (Complex using Subquery/FROM): Implement a 10% premium on all gourmet dishes within 'Mains' category
UPDATE menu_items 
SET price = price * 1.10 
FROM categories 
WHERE menu_items.category_id = categories.category_id 
  AND categories.category_name = 'Mains';

-- DELETE WITH TRANSACTION, RETURNING AND ROLLBACK
-- Business Logic Case: Purging canceled orders from database logs while tracking item historical reference IDs
BEGIN;

DELETE FROM order_items 
WHERE order_id IN (SELECT order_id FROM orders WHERE status = 'Cancelled')
RETURNING order_item_id, order_id, total_price;

DELETE FROM orders 
WHERE status = 'Cancelled'
RETURNING order_id, customer_id, status;

-- Rollback explicitly executed to preserve test environment data architecture for defense demonstration
ROLLBACK;