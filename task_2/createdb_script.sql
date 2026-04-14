CREATE SCHEMA IF NOT EXISTS cinema;
SET search_path TO cinema;

CREATE TABLE IF NOT EXISTS cinema.movies (
    movie_id SERIAL PRIMARY KEY,
    title VARCHAR(200) NOT NULL,
    genre VARCHAR(100) NOT NULL,
    duration_minutes INT NOT NULL CHECK (duration_minutes > 0),
    release_date DATE NOT NULL CONSTRAINT check_release_date CHECK (release_date > '2026-01-01'),
    rating VARCHAR(10) NOT NULL
);

CREATE TABLE IF NOT EXISTS cinema.theaters (
    theater_id SERIAL PRIMARY KEY,
    name VARCHAR(150) NOT NULL,
    location VARCHAR(200) NOT NULL,
    phone VARCHAR(20) UNIQUE
);

CREATE TABLE IF NOT EXISTS cinema.halls (
    hall_id SERIAL PRIMARY KEY,
    theater_id INT NOT NULL,
    hall_name VARCHAR(50) NOT NULL,
    capacity INT NOT NULL CHECK (capacity > 0),
    CONSTRAINT fk_theater FOREIGN KEY (theater_id) REFERENCES cinema.theaters(theater_id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS cinema.seats (
    seat_id SERIAL PRIMARY KEY,
    hall_id INT NOT NULL,
    row_no INT NOT NULL CHECK (row_no > 0),
    seat_number INT NOT NULL CHECK (seat_number > 0),
    UNIQUE (hall_id, row_no, seat_number),
    CONSTRAINT fk_hall FOREIGN KEY (hall_id) REFERENCES cinema.halls(hall_id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS cinema.screenings (
    screening_id SERIAL PRIMARY KEY,
    movie_id INT NOT NULL,
    hall_id INT NOT NULL,
    start_time TIMESTAMP NOT NULL,
    price DECIMAL(8,2) NOT NULL CHECK (price >= 0),
    CONSTRAINT fk_movie FOREIGN KEY (movie_id) REFERENCES cinema.movies(movie_id) ON DELETE CASCADE,
    CONSTRAINT fk_hall_screening FOREIGN KEY (hall_id) REFERENCES cinema.halls(hall_id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS cinema.customers (
    customer_id SERIAL PRIMARY KEY,
    name VARCHAR(150) NOT NULL,
    email VARCHAR(150) UNIQUE NOT NULL,
    gender CHAR(1) NOT NULL CHECK (gender IN ('M', 'F', 'O'))
);

CREATE TABLE IF NOT EXISTS cinema.tickets (
    ticket_id SERIAL PRIMARY KEY,
    screening_id INT NOT NULL,
    customer_id INT NOT NULL,
    purchase_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    status VARCHAR(20) DEFAULT 'PURCHASED' CHECK (status IN ('PURCHASED', 'CANCELLED', 'REFUNDED')),
    CONSTRAINT fk_screening FOREIGN KEY (screening_id) REFERENCES cinema.screenings(screening_id),
    CONSTRAINT fk_customer FOREIGN KEY (customer_id) REFERENCES cinema.customers(customer_id)
);

CREATE TABLE IF NOT EXISTS cinema.ticket_seats (
    ticket_id INT NOT NULL,
    seat_id INT NOT NULL,
    PRIMARY KEY (ticket_id, seat_id),
    CONSTRAINT fk_ticket FOREIGN KEY (ticket_id) REFERENCES cinema.tickets(ticket_id) ON DELETE CASCADE,
    CONSTRAINT fk_seat FOREIGN KEY (seat_id) REFERENCES cinema.seats(seat_id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS cinema.reservations (
    reservation_id SERIAL PRIMARY KEY,
    customer_id INT NOT NULL,
    screening_id INT NOT NULL,
    reservation_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_res_customer FOREIGN KEY (customer_id) REFERENCES cinema.customers(customer_id),
    CONSTRAINT fk_res_screening FOREIGN KEY (screening_id) REFERENCES cinema.screenings(screening_id)
);

CREATE TABLE IF NOT EXISTS cinema.roles (
    role_id SERIAL PRIMARY KEY,
    role_name VARCHAR(100) NOT NULL UNIQUE
);

CREATE TABLE IF NOT EXISTS cinema.employees (
    employee_id SERIAL PRIMARY KEY,
    theater_id INT NOT NULL,
    role_id INT NOT NULL,
    full_name VARCHAR(150) NOT NULL,
    hire_date DATE DEFAULT CURRENT_DATE,
    CONSTRAINT fk_emp_theater FOREIGN KEY (theater_id) REFERENCES cinema.theaters(theater_id),
    CONSTRAINT fk_emp_role FOREIGN KEY (role_id) REFERENCES cinema.roles(role_id)
);

CREATE TABLE IF NOT EXISTS cinema.salaries (
    salary_id SERIAL PRIMARY KEY,
    employee_id INT NOT NULL,
    base_salary DECIMAL(10,2) NOT NULL CHECK (base_salary > 0),
    bonus DECIMAL(10,2) DEFAULT 0 CHECK (bonus >= 0),
    total_paid DECIMAL(10,2) GENERATED ALWAYS AS (base_salary + bonus) STORED,
    payment_date DATE NOT NULL,
    CONSTRAINT fk_salary_employee FOREIGN KEY (employee_id) REFERENCES cinema.employees(employee_id) ON DELETE CASCADE
);

INSERT INTO cinema.roles (role_name) VALUES ('Менеджер'), ('Кассир'), ('Техник');

INSERT INTO cinema.theaters (name, location, phone) VALUES 
('Победа', 'Центральная ул., 1', '+79991234567'),
('Звезда', 'Морской пр., 12', '+79997654321');

INSERT INTO cinema.halls (theater_id, hall_name, capacity) VALUES 
(1, 'Красный зал', 50),
(1, 'VIP зал', 10),
(2, 'Главный зал', 100);

INSERT INTO cinema.seats (hall_id, row_no, seat_number) VALUES 
(1, 1, 1), (1, 1, 2), (1, 1, 3), (1, 2, 1), (1, 2, 2);

INSERT INTO cinema.movies (title, genre, duration_minutes, release_date, rating) VALUES 
('Космическая Одиссея 2026', 'Sci-Fi', 140, '2026-05-10', '12+'),
('Путь программиста', 'Drama', 110, '2026-02-20', '6+');

INSERT INTO cinema.screenings (movie_id, hall_id, start_time, price) VALUES 
(1, 1, '2026-05-12 18:00:00', 500.00),
(2, 3, '2026-02-21 20:00:00', 400.00);

INSERT INTO cinema.customers (name, email, gender) VALUES 
('Иван Петров', 'ivan@mail.ru', 'M'),
('Анна Сидорова', 'anna@gmail.com', 'F');

INSERT INTO cinema.employees (theater_id, role_id, full_name, hire_date) VALUES 
(1, 1, 'Сергеев Сергей', '2026-01-05');

INSERT INTO cinema.salaries (employee_id, base_salary, bonus, payment_date) VALUES 
(1, 60000.00, 5000.00, '2026-03-01');

INSERT INTO cinema.tickets (screening_id, customer_id, status) VALUES (1, 1, 'PURCHASED');

INSERT INTO cinema.ticket_seats (ticket_id, seat_id) VALUES (1, 1);
