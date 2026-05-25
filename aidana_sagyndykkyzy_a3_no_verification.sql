create schema if not exists cinema;
set search_path to cinema, public;

-- ====== cleanup for pgadmin query tool (no verification, no do blocks, no psql commands) ======
drop user if exists db_reader_user;
drop user if exists db_admin_user;
drop role if exists cinema_readonly;
drop role if exists cinema_admin;

create table if not exists cinema.movies (
    movie_id serial primary key,
    title varchar(200) not null,
    genre varchar(100) not null,
    duration_minutes int not null check (duration_minutes > 0),
    release_date date not null constraint check_release_date check (release_date > '2026-01-01'),
    rating varchar(10) not null
);

create table if not exists cinema.theaters (
    theater_id serial primary key,
    name varchar(150) not null,
    location varchar(200) not null,
    phone varchar(20) unique
);

create table if not exists cinema.halls (
    hall_id serial primary key,
    theater_id int not null,
    hall_name varchar(50) not null,
    capacity int not null check (capacity > 0),
    constraint fk_theater foreign key (theater_id)
        references cinema.theaters(theater_id) on delete cascade
);

create table if not exists cinema.seats (
    seat_id serial primary key,
    hall_id int not null,
    row_no int not null check (row_no > 0),
    seat_number int not null check (seat_number > 0),
    unique (hall_id, row_no, seat_number),
    constraint fk_hall foreign key (hall_id)
        references cinema.halls(hall_id) on delete cascade
);

create table if not exists cinema.screenings (
    screening_id serial primary key,
    movie_id int not null,
    hall_id int not null,
    start_time timestamp not null,
    price decimal(8, 2) not null check (price >= 0),
    constraint fk_movie foreign key (movie_id)
        references cinema.movies(movie_id) on delete cascade,
    constraint fk_hall_screening foreign key (hall_id)
        references cinema.halls(hall_id) on delete cascade
);

create table if not exists cinema.customers (
    customer_id serial primary key,
    name varchar(150) not null,
    email varchar(150) unique not null,
    gender char(1) not null check (gender in ('M', 'F', 'O'))
);

create table if not exists cinema.tickets (
    ticket_id serial primary key,
    screening_id int not null,
    customer_id int not null,
    purchase_time timestamp default current_timestamp,
    status varchar(20) default 'PURCHASED' check (status in ('PURCHASED', 'CANCELLED', 'REFUNDED')),
    constraint fk_screening foreign key (screening_id)
        references cinema.screenings(screening_id),
    constraint fk_customer foreign key (customer_id)
        references cinema.customers(customer_id)
);

create table if not exists cinema.ticket_seats (
    ticket_id int not null,
    seat_id int not null,
    primary key (ticket_id, seat_id),
    constraint fk_ticket foreign key (ticket_id)
        references cinema.tickets(ticket_id) on delete cascade,
    constraint fk_seat foreign key (seat_id)
        references cinema.seats(seat_id) on delete cascade
);

create table if not exists cinema.reservations (
    reservation_id serial primary key,
    customer_id int not null,
    screening_id int not null,
    reservation_time timestamp default current_timestamp,
    constraint fk_res_customer foreign key (customer_id)
        references cinema.customers(customer_id),
    constraint fk_res_screening foreign key (screening_id)
        references cinema.screenings(screening_id)
);

create table if not exists cinema.roles (
    role_id serial primary key,
    role_name varchar(100) not null unique
);

create table if not exists cinema.employees (
    employee_id serial primary key,
    theater_id int not null,
    role_id int not null,
    full_name varchar(150) not null,
    hire_date date default current_date,
    constraint fk_emp_theater foreign key (theater_id)
        references cinema.theaters(theater_id),
    constraint fk_emp_role foreign key (role_id)
        references cinema.roles(role_id)
);

create table if not exists cinema.salaries (
    salary_id serial primary key,
    employee_id int not null,
    base_salary decimal(10, 2) not null check (base_salary > 0),
    bonus decimal(10, 2) default 0 check (bonus >= 0),
    total_paid decimal(10, 2) generated always as (base_salary + bonus) stored,
    payment_date date not null,
    constraint fk_salary_employee foreign key (employee_id)
        references cinema.employees(employee_id) on delete cascade
);

-- ====== truncate in child-to-parent order before inserts ======
truncate table
    cinema.ticket_seats,
    cinema.salaries,
    cinema.tickets,
    cinema.reservations,
    cinema.employees,
    cinema.screenings,
    cinema.seats,
    cinema.halls,
    cinema.customers,
    cinema.roles,
    cinema.movies,
    cinema.theaters
restart identity;

-- ====== dml insert ======
insert into cinema.roles (role_name)
values
    ('Менеджер'),
    ('Кассир'),
    ('Техник'),
    ('Администратор зала'),
    ('Контролер билетов');

insert into cinema.theaters (name, location, phone)
values
    ('Победа', 'Центральная ул., 1, Алматы', '+77011234567'),
    ('Звезда', 'Морской пр., 12, Актау', '+77017654321'),
    ('Арман', 'Абая пр., 45, Астана', '+77019876543'),
    ('Керуен Cinema', 'Достык ул., 9, Шымкент', '+77015554433'),
    ('Сарыарка', 'Бухар жырау пр., 72, Караганда', '+77012223344');

insert into cinema.halls (theater_id, hall_name, capacity)
values
    ((select theater_id from cinema.theaters where name = 'Победа'), 'Красный зал', 50),
    ((select theater_id from cinema.theaters where name = 'Победа'), 'VIP зал', 12),
    ((select theater_id from cinema.theaters where name = 'Звезда'), 'Главный зал', 100),
    ((select theater_id from cinema.theaters where name = 'Арман'), 'IMAX зал', 140),
    ((select theater_id from cinema.theaters where name = 'Керуен Cinema'), 'Семейный зал', 80);

insert into cinema.seats (hall_id, row_no, seat_number)
values
    ((select h.hall_id from cinema.halls h join cinema.theaters t on t.theater_id = h.theater_id where t.name = 'Победа' and h.hall_name = 'Красный зал'), 1, 1),
    ((select h.hall_id from cinema.halls h join cinema.theaters t on t.theater_id = h.theater_id where t.name = 'Победа' and h.hall_name = 'Красный зал'), 1, 2),
    ((select h.hall_id from cinema.halls h join cinema.theaters t on t.theater_id = h.theater_id where t.name = 'Победа' and h.hall_name = 'VIP зал'), 1, 1),
    ((select h.hall_id from cinema.halls h join cinema.theaters t on t.theater_id = h.theater_id where t.name = 'Звезда' and h.hall_name = 'Главный зал'), 2, 5),
    ((select h.hall_id from cinema.halls h join cinema.theaters t on t.theater_id = h.theater_id where t.name = 'Арман' and h.hall_name = 'IMAX зал'), 3, 7),
    ((select h.hall_id from cinema.halls h join cinema.theaters t on t.theater_id = h.theater_id where t.name = 'Керуен Cinema' and h.hall_name = 'Семейный зал'), 4, 10);

insert into cinema.movies (title, genre, duration_minutes, release_date, rating)
values
    ('Космическая Одиссея 2026', 'Sci-Fi', 140, '2026-05-10', '12+'),
    ('Путь программиста', 'Drama', 110, '2026-02-20', '6+'),
    ('Алматы кеші', 'Romance', 98, '2026-03-15', '12+'),
    ('Последний экспресс', 'Thriller', 125, '2026-04-22', '16+'),
    ('Балалар әлемі', 'Animation', 86, '2026-06-01', '0+');

insert into cinema.screenings (movie_id, hall_id, start_time, price)
values
    (
        (select movie_id from cinema.movies where title = 'Космическая Одиссея 2026'),
        (select h.hall_id from cinema.halls h join cinema.theaters t on t.theater_id = h.theater_id where t.name = 'Победа' and h.hall_name = 'Красный зал'),
        '2026-05-12 18:00:00',
        500.00
    ),
    (
        (select movie_id from cinema.movies where title = 'Путь программиста'),
        (select h.hall_id from cinema.halls h join cinema.theaters t on t.theater_id = h.theater_id where t.name = 'Звезда' and h.hall_name = 'Главный зал'),
        '2026-02-21 20:00:00',
        400.00
    ),
    (
        (select movie_id from cinema.movies where title = 'Алматы кеші'),
        (select h.hall_id from cinema.halls h join cinema.theaters t on t.theater_id = h.theater_id where t.name = 'Победа' and h.hall_name = 'VIP зал'),
        '2026-03-20 19:30:00',
        800.00
    ),
    (
        (select movie_id from cinema.movies where title = 'Последний экспресс'),
        (select h.hall_id from cinema.halls h join cinema.theaters t on t.theater_id = h.theater_id where t.name = 'Арман' and h.hall_name = 'IMAX зал'),
        '2026-04-25 21:00:00',
        1200.00
    ),
    (
        (select movie_id from cinema.movies where title = 'Балалар әлемі'),
        (select h.hall_id from cinema.halls h join cinema.theaters t on t.theater_id = h.theater_id where t.name = 'Керуен Cinema' and h.hall_name = 'Семейный зал'),
        '2026-06-02 11:00:00',
        350.00
    );

insert into cinema.customers (name, email, gender)
values
    ('Иван Петров', 'ivan.petrov@example.kz', 'M'),
    ('Анна Сидорова', 'anna.sidorova@example.kz', 'F'),
    ('Данияр Ахметов', 'daniyar.akhmetov@example.kz', 'M'),
    ('Айгуль Нурланова', 'aigul.nurlanova@example.kz', 'F'),
    ('Самат Ким', 'samat.kim@example.kz', 'M');

insert into cinema.tickets (screening_id, customer_id, purchase_time, status)
values
    ((select s.screening_id from cinema.screenings s join cinema.movies m on m.movie_id = s.movie_id where m.title = 'Космическая Одиссея 2026'), (select customer_id from cinema.customers where email = 'ivan.petrov@example.kz'), '2026-05-11 10:15:00', 'PURCHASED'),
    ((select s.screening_id from cinema.screenings s join cinema.movies m on m.movie_id = s.movie_id where m.title = 'Путь программиста'), (select customer_id from cinema.customers where email = 'anna.sidorova@example.kz'), '2026-02-20 14:40:00', 'PURCHASED'),
    ((select s.screening_id from cinema.screenings s join cinema.movies m on m.movie_id = s.movie_id where m.title = 'Алматы кеші'), (select customer_id from cinema.customers where email = 'daniyar.akhmetov@example.kz'), '2026-03-19 16:20:00', 'CANCELLED'),
    ((select s.screening_id from cinema.screenings s join cinema.movies m on m.movie_id = s.movie_id where m.title = 'Последний экспресс'), (select customer_id from cinema.customers where email = 'aigul.nurlanova@example.kz'), '2026-04-24 09:05:00', 'REFUNDED'),
    ((select s.screening_id from cinema.screenings s join cinema.movies m on m.movie_id = s.movie_id where m.title = 'Балалар әлемі'), (select customer_id from cinema.customers where email = 'samat.kim@example.kz'), '2026-06-01 12:30:00', 'PURCHASED');

insert into cinema.ticket_seats (ticket_id, seat_id)
values
    ((select ti.ticket_id from cinema.tickets ti join cinema.customers c on c.customer_id = ti.customer_id where c.email = 'ivan.petrov@example.kz'), (select se.seat_id from cinema.seats se join cinema.halls h on h.hall_id = se.hall_id join cinema.theaters th on th.theater_id = h.theater_id where th.name = 'Победа' and h.hall_name = 'Красный зал' and se.row_no = 1 and se.seat_number = 1)),
    ((select ti.ticket_id from cinema.tickets ti join cinema.customers c on c.customer_id = ti.customer_id where c.email = 'anna.sidorova@example.kz'), (select se.seat_id from cinema.seats se join cinema.halls h on h.hall_id = se.hall_id join cinema.theaters th on th.theater_id = h.theater_id where th.name = 'Звезда' and h.hall_name = 'Главный зал' and se.row_no = 2 and se.seat_number = 5)),
    ((select ti.ticket_id from cinema.tickets ti join cinema.customers c on c.customer_id = ti.customer_id where c.email = 'daniyar.akhmetov@example.kz'), (select se.seat_id from cinema.seats se join cinema.halls h on h.hall_id = se.hall_id join cinema.theaters th on th.theater_id = h.theater_id where th.name = 'Победа' and h.hall_name = 'VIP зал' and se.row_no = 1 and se.seat_number = 1)),
    ((select ti.ticket_id from cinema.tickets ti join cinema.customers c on c.customer_id = ti.customer_id where c.email = 'aigul.nurlanova@example.kz'), (select se.seat_id from cinema.seats se join cinema.halls h on h.hall_id = se.hall_id join cinema.theaters th on th.theater_id = h.theater_id where th.name = 'Арман' and h.hall_name = 'IMAX зал' and se.row_no = 3 and se.seat_number = 7)),
    ((select ti.ticket_id from cinema.tickets ti join cinema.customers c on c.customer_id = ti.customer_id where c.email = 'samat.kim@example.kz'), (select se.seat_id from cinema.seats se join cinema.halls h on h.hall_id = se.hall_id join cinema.theaters th on th.theater_id = h.theater_id where th.name = 'Керуен Cinema' and h.hall_name = 'Семейный зал' and se.row_no = 4 and se.seat_number = 10));

insert into cinema.reservations (customer_id, screening_id, reservation_time)
values
    ((select customer_id from cinema.customers where email = 'ivan.petrov@example.kz'), (select s.screening_id from cinema.screenings s join cinema.movies m on m.movie_id = s.movie_id where m.title = 'Космическая Одиссея 2026'), '2026-05-10 12:00:00'),
    ((select customer_id from cinema.customers where email = 'anna.sidorova@example.kz'), (select s.screening_id from cinema.screenings s join cinema.movies m on m.movie_id = s.movie_id where m.title = 'Путь программиста'), '2026-02-19 18:25:00'),
    ((select customer_id from cinema.customers where email = 'daniyar.akhmetov@example.kz'), (select s.screening_id from cinema.screenings s join cinema.movies m on m.movie_id = s.movie_id where m.title = 'Алматы кеші'), '2026-03-18 20:10:00'),
    ((select customer_id from cinema.customers where email = 'aigul.nurlanova@example.kz'), (select s.screening_id from cinema.screenings s join cinema.movies m on m.movie_id = s.movie_id where m.title = 'Последний экспресс'), '2026-04-23 11:45:00'),
    ((select customer_id from cinema.customers where email = 'samat.kim@example.kz'), (select s.screening_id from cinema.screenings s join cinema.movies m on m.movie_id = s.movie_id where m.title = 'Балалар әлемі'), '2026-05-31 15:35:00');

insert into cinema.employees (theater_id, role_id, full_name, hire_date)
values
    ((select theater_id from cinema.theaters where name = 'Победа'), (select role_id from cinema.roles where role_name = 'Менеджер'), 'Сергеев Сергей', '2026-01-05'),
    ((select theater_id from cinema.theaters where name = 'Звезда'), (select role_id from cinema.roles where role_name = 'Кассир'), 'Марина Волкова', '2026-01-12'),
    ((select theater_id from cinema.theaters where name = 'Арман'), (select role_id from cinema.roles where role_name = 'Техник'), 'Бекзат Омаров', '2026-02-01'),
    ((select theater_id from cinema.theaters where name = 'Керуен Cinema'), (select role_id from cinema.roles where role_name = 'Администратор зала'), 'Лаура Есенова', '2026-02-15'),
    ((select theater_id from cinema.theaters where name = 'Сарыарка'), (select role_id from cinema.roles where role_name = 'Контролер билетов'), 'Руслан Каримов', '2026-03-01');

insert into cinema.salaries (employee_id, base_salary, bonus, payment_date)
values
    ((select employee_id from cinema.employees where full_name = 'Сергеев Сергей'), 600000.00, 50000.00, '2026-03-01'),
    ((select employee_id from cinema.employees where full_name = 'Марина Волкова'), 380000.00, 25000.00, '2026-03-01'),
    ((select employee_id from cinema.employees where full_name = 'Бекзат Омаров'), 420000.00, 30000.00, '2026-03-01'),
    ((select employee_id from cinema.employees where full_name = 'Лаура Есенова'), 450000.00, 35000.00, '2026-03-01'),
    ((select employee_id from cinema.employees where full_name = 'Руслан Каримов'), 330000.00, 20000.00, '2026-03-01');

-- ====== dcl: roles, users, and permissions ======
create role cinema_admin;
create role cinema_readonly;

grant usage on schema public to cinema_admin, cinema_readonly;
grant usage on schema cinema to cinema_admin, cinema_readonly;

grant select, insert, update, delete on all tables in schema cinema to cinema_admin;
grant usage, select, update on all sequences in schema cinema to cinema_admin;

grant select on all tables in schema cinema to cinema_readonly;
revoke update, delete on all tables in schema cinema from cinema_readonly;

create user db_admin_user with password 'AdminPass2026!';
create user db_reader_user with password 'ReaderPass2026!';

grant cinema_admin to db_admin_user;
grant cinema_readonly to db_reader_user;
revoke cinema_readonly from db_admin_user;

-- ====== dml update 1: customer changed email address ======
select c.customer_id, c.name, c.email
from cinema.customers as c
where c.email = 'ivan.petrov@example.kz';
-- preview row count: 1

update cinema.customers
set email = 'ivan.petrov@cinema.kz'
where email = 'ivan.petrov@example.kz';
-- updated row count: 1

-- ====== dml update 2: ticket was refunded after customer request ======
select ti.ticket_id, c.name, ti.status
from cinema.tickets as ti
join cinema.customers as c on c.customer_id = ti.customer_id
where c.email = 'aigul.nurlanova@example.kz';
-- preview row count: 1

update cinema.tickets
set status = 'REFUNDED'
where customer_id = (
    select customer_id
    from cinema.customers
    where email = 'aigul.nurlanova@example.kz'
);
-- updated row count: 1

-- ====== dml update from: VIP hall screenings receive a premium price ======
select s.screening_id, m.title, h.hall_name, s.price
from cinema.screenings as s
join cinema.movies as m on m.movie_id = s.movie_id
join cinema.halls as h on h.hall_id = s.hall_id
where h.hall_name = 'VIP зал';
-- preview row count: 1

update cinema.screenings as s
set price = s.price + 300.00
from cinema.halls as h
where h.hall_id = s.hall_id
  and h.hall_name = 'VIP зал';
-- updated row count: 1

-- ====== dml delete: safe transaction with rollback ======
-- Business reason: cancelled tickets are obsolete for revenue reporting, so they are removed from the active ticket list after cancellation processing.
select ti.ticket_id, c.name, m.title, ti.status
from cinema.tickets as ti
join cinema.customers as c on c.customer_id = ti.customer_id
join cinema.screenings as s on s.screening_id = ti.screening_id
join cinema.movies as m on m.movie_id = s.movie_id
where ti.status = 'CANCELLED';
-- preview row count: 1

begin;

delete from cinema.tickets
where status = 'CANCELLED';
-- deleted row count inside transaction: 1

select count(*) as active_ticket_rows_after_delete
from cinema.tickets;
-- count inside transaction: 4

rollback;
