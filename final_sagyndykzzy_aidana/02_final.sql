-- ===== PART 2: CREATE =====

drop schema if exists restaurant_management cascade;
create schema if not exists restaurant_management;
set search_path to restaurant_management;

create table if not exists customers (
    customer_id serial,
    full_name varchar(100) not null,
    phone varchar(20),
    email varchar(120) not null,
    created_at timestamp not null default now(),
    constraint pk_customers primary key (customer_id),
    constraint uq_customers_email unique (email)
);

create table if not exists restaurant_tables (
    table_id serial,
    table_number int not null,
    seats int not null,
    status varchar(20) not null default 'available',
    constraint pk_restaurant_tables primary key (table_id),
    constraint uq_restaurant_tables_number unique (table_number),
    constraint chk_restaurant_tables_seats check (seats > 0)
);

create table if not exists staff (
    staff_id serial,
    full_name varchar(100) not null,
    position varchar(50) not null,
    salary numeric(10,2),
    employment_status varchar(20) not null,
    constraint pk_staff primary key (staff_id),
    constraint chk_staff_salary check (salary >= 0),
    constraint chk_staff_status check (employment_status in ('active', 'on_leave', 'terminated'))
);

create table if not exists shifts (
    shift_id serial,
    shift_date date not null,
    start_time time not null,
    end_time time not null,
    constraint pk_shifts primary key (shift_id),
    constraint chk_shifts_date check (shift_date > date '2026-01-01')
);

-- many-to-many: one staff member can work many shifts, and one shift has many staff members.
create table if not exists staff_shifts (
    staff_id int not null,
    shift_id int not null,
    assigned_role varchar(50) not null default 'floor',
    constraint pk_staff_shifts primary key (staff_id, shift_id),
    constraint fk_staff_shifts_staff foreign key (staff_id)
        references staff (staff_id) on delete cascade,
    constraint fk_staff_shifts_shifts foreign key (shift_id)
        references shifts (shift_id) on delete cascade
);

create table if not exists categories (
    category_id serial,
    category_name varchar(50) not null,
    constraint pk_categories primary key (category_id),
    constraint uq_categories_name unique (category_name)
);

create table if not exists menu_items (
    menu_item_id serial,
    category_id int not null,
    item_name varchar(100) not null,
    price numeric(10,2) not null,
    available boolean not null default true,
    constraint pk_menu_items primary key (menu_item_id),
    constraint uq_menu_items_name unique (item_name),
    constraint fk_menu_items_categories foreign key (category_id)
        references categories (category_id) on delete restrict,
    constraint chk_menu_items_price check (price >= 0)
);

create table if not exists reservations (
    reservation_id serial,
    customer_id int not null,
    table_id int not null,
    reservation_time timestamp not null,
    guests_count int not null default 1,
    constraint pk_reservations primary key (reservation_id),
    constraint fk_reservations_customers foreign key (customer_id)
        references customers (customer_id) on delete cascade,
    constraint fk_reservations_tables foreign key (table_id)
        references restaurant_tables (table_id) on delete restrict,
    constraint chk_reservations_date check (reservation_time > timestamp '2026-01-01 00:00:00'),
    constraint chk_reservations_guests check (guests_count > 0)
);

create table if not exists orders (
    order_id serial,
    customer_id int,
    table_id int not null,
    staff_id int not null,
    order_date timestamp not null default now(),
    status varchar(20) not null default 'pending',
    constraint pk_orders primary key (order_id),
    constraint fk_orders_customers foreign key (customer_id)
        references customers (customer_id) on delete set null,
    constraint fk_orders_tables foreign key (table_id)
        references restaurant_tables (table_id) on delete restrict,
    constraint fk_orders_staff foreign key (staff_id)
        references staff (staff_id) on delete restrict,
    constraint chk_orders_status check (status in ('pending', 'processing', 'served', 'cancelled'))
);

create table if not exists order_items (
    order_item_id serial,
    order_id int not null,
    menu_item_id int not null,
    quantity int not null default 1,
    unit_price numeric(10,2) not null,
    total_price numeric(10,2) generated always as (quantity * unit_price) stored,
    constraint pk_order_items primary key (order_item_id),
    constraint fk_order_items_orders foreign key (order_id)
        references orders (order_id) on delete cascade,
    constraint fk_order_items_menu_items foreign key (menu_item_id)
        references menu_items (menu_item_id) on delete restrict,
    constraint chk_order_items_quantity check (quantity > 0),
    constraint chk_order_items_unit_price check (unit_price >= 0)
);

-- ===== PART 3: ALTER TABLE =====

-- phone numbers may include country codes and extensions.
alter table customers alter column phone type varchar(30);

-- special reservation requests were planned after the first reservation design.
alter table reservations add column if not exists special_requests varchar(250);

-- table status options must be controlled by restaurant operations.
alter table restaurant_tables drop constraint if exists chk_restaurant_tables_status;
alter table restaurant_tables add constraint chk_restaurant_tables_status
check (status in ('available', 'occupied', 'reserved', 'out_of_service'));

-- default salary helps when new staff records are created before payroll details are finalized.
alter table staff alter column salary set default 3200.00;

-- "job_title" is clearer than "position" in staff reports.
alter table staff rename column position to job_title;

-- available boolean is removed because menu availability will later become a richer status model.
alter table menu_items drop column if exists available;

-- ===== PART 4: INSERT =====

truncate table
    staff_shifts,
    reservations,
    order_items,
    orders,
    menu_items,
    categories,
    shifts,
    staff,
    restaurant_tables,
    customers
restart identity cascade;

insert into customers (full_name, phone, email) values
('Ansar Olzhagul', '+15550192', 'ansar.olzhagul@example.kz'),
('Rasul Orazakhay', '+15550143', 'rasul.orazakhay@example.kz'),
('Albina Marat', '+77015552', 'albina.marat@example.kz'),
('Anuar Quanysh', '+77029991', 'anuar.quanysh@example.kz'),
('Eren Erkinbek', '+77073334', 'eren.erkinbek@example.kz'),
('Dias Zholgali', '+77074445', 'dias.zholgali@example.kz');

insert into restaurant_tables (table_number, seats, status) values
(10, 2, 'available'),
(11, 2, 'available'),
(20, 4, 'available'),
(21, 4, 'available'),
(30, 8, 'available');

insert into staff (full_name, job_title, salary, employment_status) values
('Utezhan Student', 'manager', 4500.00, 'active'),
('Adelya Umbetaliyeva', 'chef', 5000.00, 'active'),
('Elnazar Amanjan', 'waiter', 2800.00, 'active'),
('Saida Zhakieva', 'waiter', 2900.00, 'active'),
('Aziza Erbolatqyzy', 'hostess', 3100.00, 'active');

insert into shifts (shift_date, start_time, end_time) values
('2026-06-01', '08:00:00', '16:00:00'),
('2026-06-01', '16:00:00', '23:59:00'),
('2026-06-02', '08:00:00', '16:00:00'),
('2026-06-02', '16:00:00', '23:59:00'),
('2026-06-03', '16:00:00', '23:59:00');

insert into categories (category_name) values
('Starters'),
('Mains'),
('Desserts'),
('Beverages'),
('Sides');

insert into menu_items (category_id, item_name, price) values
((select category_id from categories where category_name = 'Starters'), 'Garlic Bread', 1200.00),
((select category_id from categories where category_name = 'Starters'), 'Spring Rolls', 1800.00),
((select category_id from categories where category_name = 'Mains'), 'Wagyu Ribeye', 14500.00),
((select category_id from categories where category_name = 'Mains'), 'Salmon Fillet', 8900.00),
((select category_id from categories where category_name = 'Mains'), 'Truffle Pasta', 6200.00),
((select category_id from categories where category_name = 'Desserts'), 'Lava Cake', 2400.00),
((select category_id from categories where category_name = 'Desserts'), 'Cheesecake', 2200.00),
((select category_id from categories where category_name = 'Beverages'), 'Craft Lemonade', 1500.00),
((select category_id from categories where category_name = 'Beverages'), 'Flat White', 1100.00),
((select category_id from categories where category_name = 'Sides'), 'French Fries', 950.00);

insert into reservations (customer_id, table_id, reservation_time, guests_count, special_requests) values
((select customer_id from customers where email = 'ansar.olzhagul@example.kz'), (select table_id from restaurant_tables where table_number = 10), '2026-06-04 19:00:00', 2, 'Window seat'),
((select customer_id from customers where email = 'rasul.orazakhay@example.kz'), (select table_id from restaurant_tables where table_number = 20), '2026-06-04 20:30:00', 4, 'Birthday celebration'),
((select customer_id from customers where email = 'albina.marat@example.kz'), (select table_id from restaurant_tables where table_number = 30), '2026-06-05 21:00:00', 7, 'VIP privacy screen'),
((select customer_id from customers where email = 'anuar.quanysh@example.kz'), (select table_id from restaurant_tables where table_number = 11), '2026-06-05 13:00:00', 2, null),
((select customer_id from customers where email = 'eren.erkinbek@example.kz'), (select table_id from restaurant_tables where table_number = 21), '2026-06-06 18:00:00', 3, 'High chair for kid');

insert into orders (customer_id, table_id, staff_id, order_date, status) values
((select customer_id from customers where email = 'ansar.olzhagul@example.kz'), (select table_id from restaurant_tables where table_number = 10), (select staff_id from staff where full_name = 'Elnazar Amanjan'), '2026-06-03 17:15:00', 'served'),
((select customer_id from customers where email = 'rasul.orazakhay@example.kz'), (select table_id from restaurant_tables where table_number = 20), (select staff_id from staff where full_name = 'Saida Zhakieva'), '2026-06-03 17:30:00', 'processing'),
(null, (select table_id from restaurant_tables where table_number = 11), (select staff_id from staff where full_name = 'Elnazar Amanjan'), '2026-06-03 17:45:00', 'pending'),
((select customer_id from customers where email = 'albina.marat@example.kz'), (select table_id from restaurant_tables where table_number = 30), (select staff_id from staff where full_name = 'Saida Zhakieva'), '2026-06-03 18:00:00', 'served'),
((select customer_id from customers where email = 'anuar.quanysh@example.kz'), (select table_id from restaurant_tables where table_number = 21), (select staff_id from staff where full_name = 'Elnazar Amanjan'), '2026-06-03 18:15:00', 'cancelled');

-- insert ... select for the junction table; creates five realistic shift assignments.
insert into staff_shifts (staff_id, shift_id, assigned_role)
select st.staff_id, sh.shift_id,
    case
        when st.job_title = 'manager' then 'supervisor'
        when st.job_title = 'chef' then 'kitchen'
        when st.job_title = 'hostess' then 'front desk'
        else 'floor'
    end as assigned_role
from staff st
join shifts sh
    on sh.shift_date = date '2026-06-03'
where st.employment_status = 'active'
  and sh.start_time = time '16:00:00';

insert into order_items (order_id, menu_item_id, quantity, unit_price) values
((select o.order_id from orders o join customers c on c.customer_id = o.customer_id where c.email = 'ansar.olzhagul@example.kz' and o.order_date = timestamp '2026-06-03 17:15:00'), (select menu_item_id from menu_items where item_name = 'Garlic Bread'), 1, 1200.00),
((select o.order_id from orders o join customers c on c.customer_id = o.customer_id where c.email = 'ansar.olzhagul@example.kz' and o.order_date = timestamp '2026-06-03 17:15:00'), (select menu_item_id from menu_items where item_name = 'Truffle Pasta'), 1, 6200.00),
((select o.order_id from orders o join customers c on c.customer_id = o.customer_id where c.email = 'ansar.olzhagul@example.kz' and o.order_date = timestamp '2026-06-03 17:15:00'), (select menu_item_id from menu_items where item_name = 'Craft Lemonade'), 2, 1500.00),
((select o.order_id from orders o join customers c on c.customer_id = o.customer_id where c.email = 'rasul.orazakhay@example.kz' and o.order_date = timestamp '2026-06-03 17:30:00'), (select menu_item_id from menu_items where item_name = 'Spring Rolls'), 2, 1800.00),
((select o.order_id from orders o join customers c on c.customer_id = o.customer_id where c.email = 'rasul.orazakhay@example.kz' and o.order_date = timestamp '2026-06-03 17:30:00'), (select menu_item_id from menu_items where item_name = 'Salmon Fillet'), 2, 8900.00),
((select o.order_id from orders o join customers c on c.customer_id = o.customer_id where c.email = 'rasul.orazakhay@example.kz' and o.order_date = timestamp '2026-06-03 17:30:00'), (select menu_item_id from menu_items where item_name = 'Cheesecake'), 2, 2200.00),
((select o.order_id from orders o join restaurant_tables rt on rt.table_id = o.table_id where rt.table_number = 11 and o.order_date = timestamp '2026-06-03 17:45:00'), (select menu_item_id from menu_items where item_name = 'Wagyu Ribeye'), 1, 14500.00),
((select o.order_id from orders o join restaurant_tables rt on rt.table_id = o.table_id where rt.table_number = 11 and o.order_date = timestamp '2026-06-03 17:45:00'), (select menu_item_id from menu_items where item_name = 'French Fries'), 1, 950.00),
((select o.order_id from orders o join customers c on c.customer_id = o.customer_id where c.email = 'albina.marat@example.kz' and o.order_date = timestamp '2026-06-03 18:00:00'), (select menu_item_id from menu_items where item_name = 'Wagyu Ribeye'), 4, 14500.00),
((select o.order_id from orders o join customers c on c.customer_id = o.customer_id where c.email = 'albina.marat@example.kz' and o.order_date = timestamp '2026-06-03 18:00:00'), (select menu_item_id from menu_items where item_name = 'Lava Cake'), 4, 2400.00),
((select o.order_id from orders o join customers c on c.customer_id = o.customer_id where c.email = 'albina.marat@example.kz' and o.order_date = timestamp '2026-06-03 18:00:00'), (select menu_item_id from menu_items where item_name = 'Flat White'), 4, 1100.00),
((select o.order_id from orders o join customers c on c.customer_id = o.customer_id where c.email = 'anuar.quanysh@example.kz' and o.order_date = timestamp '2026-06-03 18:15:00'), (select menu_item_id from menu_items where item_name = 'Truffle Pasta'), 2, 6200.00);

-- ===== PART 5: UPDATE + DELETE =====

-- business event: tables with active orders become occupied.
update restaurant_tables
set status = 'occupied'
where table_id in (
    select o.table_id
    from orders o
    where o.status in ('processing', 'pending')
);

-- business event: mains category receives a 10 percent premium price increase.
update menu_items mi
set price = mi.price * 1.10
from categories c
where mi.category_id = c.category_id
  and c.category_name = 'Mains';

-- business event: test deletion of cancelled orders while preserving the final database state for defense.
commit;

begin;

delete from order_items
where order_id in (
    select o.order_id
    from orders o
    where o.status = 'cancelled'
)
returning order_item_id, order_id, total_price;

delete from orders
where status = 'cancelled'
returning order_id, customer_id, status;

rollback;

-- ===== PART 6: GRANT + REVOKE =====

revoke all privileges on all tables in schema restaurant_management from restaurant_readonly;
revoke all privileges on schema restaurant_management from restaurant_readonly;
grant usage on schema restaurant_management to restaurant_readonly;
grant select on all tables in schema restaurant_management to restaurant_readonly;

revoke all privileges on all tables in schema restaurant_management from restaurant_writer;
revoke all privileges on schema restaurant_management from restaurant_writer;
grant usage on schema restaurant_management to restaurant_writer;

-- Make sure the table names are explicitly schema-qualified just in case
grant insert, update on restaurant_management.orders to restaurant_writer;
revoke update on restaurant_management.orders from restaurant_writer;

commit;
