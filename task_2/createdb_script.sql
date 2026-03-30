CREATE DATABASE IF NOT EXISTS cinema_management;
USE cinema_management;

CREATE TABLE movies (
    movie_id INT AUTO_INCREMENT PRIMARY KEY,
    title VARCHAR(200) NOT NULL,
    genre VARCHAR(100),
    duration_minutes INT NOT NULL,
    release_date DATE,
    rating VARCHAR(10)
);

CREATE TABLE theaters (
    theater_id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(150) NOT NULL,
    location VARCHAR(200),
    phone VARCHAR(20)
);

CREATE TABLE halls (
    hall_id INT AUTO_INCREMENT PRIMARY KEY,
    theater_id INT NOT NULL,
    hall_name VARCHAR(50) NOT NULL,
    capacity INT NOT NULL,
    FOREIGN KEY (theater_id)
        REFERENCES theaters(theater_id)
        ON DELETE CASCADE
);

CREATE TABLE seats (
    seat_id INT AUTO_INCREMENT PRIMARY KEY,
    hall_id INT NOT NULL,
    row_no INT NOT NULL,
    seat_number INT NOT NULL,
    UNIQUE (hall_id, row_no, seat_number),
    FOREIGN KEY (hall_id)
        REFERENCES halls(hall_id)
        ON DELETE CASCADE
);

CREATE TABLE screenings (
    screening_id INT AUTO_INCREMENT PRIMARY KEY,
    movie_id INT NOT NULL,
    hall_id INT NOT NULL,
    start_time DATETIME NOT NULL,
    price DECIMAL(8,2) NOT NULL,
    FOREIGN KEY (movie_id)
        REFERENCES movies(movie_id)
        ON DELETE CASCADE,
    FOREIGN KEY (hall_id)
        REFERENCES halls(hall_id)
        ON DELETE CASCADE
);

CREATE TABLE customers (
    customer_id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(150) NOT NULL,
    email VARCHAR(150) UNIQUE,
    phone VARCHAR(20)
);

CREATE TABLE tickets (
    ticket_id INT AUTO_INCREMENT PRIMARY KEY,
    screening_id INT NOT NULL,
    customer_id INT NOT NULL,
    purchase_time DATETIME DEFAULT CURRENT_TIMESTAMP,
    status VARCHAR(20) DEFAULT 'PURCHASED',
    FOREIGN KEY (screening_id)
        REFERENCES screenings(screening_id)
        ON DELETE CASCADE,
    FOREIGN KEY (customer_id)
        REFERENCES customers(customer_id)
        ON DELETE CASCADE
);

CREATE TABLE ticket_seats (
    ticket_id INT NOT NULL,
    seat_id INT NOT NULL,
    PRIMARY KEY (ticket_id, seat_id),
    FOREIGN KEY (ticket_id)
        REFERENCES tickets(ticket_id)
        ON DELETE CASCADE,
    FOREIGN KEY (seat_id)
        REFERENCES seats(seat_id)
        ON DELETE CASCADE
);

CREATE TABLE reservations (
    reservation_id INT AUTO_INCREMENT PRIMARY KEY,
    customer_id INT NOT NULL,
    screening_id INT NOT NULL,
    reservation_time DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (customer_id)
        REFERENCES customers(customer_id)
        ON DELETE CASCADE,
    FOREIGN KEY (screening_id)
        REFERENCES screenings(screening_id)
        ON DELETE CASCADE
);

CREATE TABLE roles (
    role_id INT AUTO_INCREMENT PRIMARY KEY,
    role_name VARCHAR(100) NOT NULL UNIQUE
);

CREATE TABLE employees (
    employee_id INT AUTO_INCREMENT PRIMARY KEY,
    theater_id INT NOT NULL,
    role_id INT NOT NULL,
    full_name VARCHAR(150) NOT NULL,
    hire_date DATE DEFAULT (CURRENT_DATE),
    FOREIGN KEY (theater_id)
        REFERENCES theaters(theater_id)
        ON DELETE CASCADE,
    FOREIGN KEY (role_id)
        REFERENCES roles(role_id)
);

CREATE TABLE salaries (
    salary_id INT AUTO_INCREMENT PRIMARY KEY,
    employee_id INT NOT NULL,
    base_salary DECIMAL(10,2) NOT NULL,
    bonus DECIMAL(10,2) DEFAULT 0,
    payment_date DATE NOT NULL,
    FOREIGN KEY (employee_id)
        REFERENCES employees(employee_id)
        ON DELETE CASCADE
);