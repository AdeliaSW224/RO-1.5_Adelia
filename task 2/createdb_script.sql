CREATE DATABASE gallery;
USE gallery;

CREATE TABLE artists (
    artist_id INT AUTO_INCREMENT PRIMARY KEY,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    birth_date DATE,
    death_date DATE,
    nationality VARCHAR(100),
    biography TEXT
);

CREATE TABLE artworks (
    artwork_id INT AUTO_INCREMENT PRIMARY KEY,
    title VARCHAR(200) NOT NULL,
    year_created INT,
    medium VARCHAR(100),
    dimensions VARCHAR(100)
);

-- artists and artworks many-to-many bridge
CREATE TABLE artist_artworks (
    artist_id INT,
    artwork_id INT,
    PRIMARY KEY (artist_id, artwork_id),
    FOREIGN KEY (artist_id) REFERENCES artists(artist_id),
    FOREIGN KEY (artwork_id) REFERENCES artworks(artwork_id)
);

CREATE TABLE restorations (
    restoration_id INT AUTO_INCREMENT PRIMARY KEY,
    artwork_id INT NOT NULL,
    restoration_date DATE NOT NULL,
    description TEXT,
    cost DECIMAL(10,2) NOT NULL,
    FOREIGN KEY (artwork_id) REFERENCES artworks(artwork_id),
    CHECK (restoration_date > '2026-01-01'),
    CHECK (cost >= 0) -- prevent negative values
);

CREATE TABLE exhibitions (
    exhibition_id INT AUTO_INCREMENT PRIMARY KEY,
    title VARCHAR(200) NOT NULL UNIQUE,
    start_date DATE NOT NULL,
    end_date DATE,
    description TEXT,
    CHECK (start_date > '2026-01-01')
);

-- exhibitions and artworks many-to-many bridge
CREATE TABLE exhibition_artworks (
    exhibition_id INT,
    artwork_id INT,
    display_order INT,
    PRIMARY KEY (exhibition_id, artwork_id),
    FOREIGN KEY (exhibition_id) REFERENCES exhibitions(exhibition_id),
    FOREIGN KEY (artwork_id) REFERENCES artworks(artwork_id)
);

CREATE TABLE employees (
    employee_id INT AUTO_INCREMENT PRIMARY KEY,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    email VARCHAR(150) UNIQUE,
    phone VARCHAR(30),
    position VARCHAR(100) NOT NULL,
    hire_date DATE
);

-- exhibitions and employees many-to-many bridge
CREATE TABLE exhibition_employees (
    exhibition_id INT,
    employee_id INT,
    role VARCHAR(100) NOT NULL,
    PRIMARY KEY (exhibition_id, employee_id),
    FOREIGN KEY (exhibition_id) REFERENCES exhibitions(exhibition_id),
    FOREIGN KEY (employee_id) REFERENCES employees(employee_id),
    CHECK (role IN ('curator','manager','guide'))
);

CREATE TABLE visitors (
    visitor_id INT AUTO_INCREMENT PRIMARY KEY,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    email VARCHAR(150) UNIQUE,
    phone VARCHAR(30)
);

CREATE TABLE ticket_types (
    ticket_type_id INT AUTO_INCREMENT PRIMARY KEY,
    type_name VARCHAR(50) NOT NULL UNIQUE,
    price DECIMAL(8,2) NOT NULL,
    CHECK (price >= 0)
);

CREATE TABLE tickets (
    ticket_id INT AUTO_INCREMENT PRIMARY KEY,
    visitor_id INT NOT NULL,
    ticket_type_id INT NOT NULL,
    exhibition_id INT NOT NULL,
    purchase_date TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    visit_date DATE NOT NULL,
    FOREIGN KEY (visitor_id) REFERENCES visitors(visitor_id),
    FOREIGN KEY (ticket_type_id) REFERENCES ticket_types(ticket_type_id),
    FOREIGN KEY (exhibition_id) REFERENCES exhibitions(exhibition_id),
    CHECK (visit_date > '2026-01-01')
);

-- sample data

INSERT INTO artists (first_name, last_name, birth_date, death_date, nationality, biography) VALUES
('Claude', 'Monet', '1840-11-14', '1926-12-05', 'French', 'Founder of French Impressionist painting.'),
('Frida', 'Kahlo', '1907-07-06', '1954-07-13', 'Mexican', 'Known for symbolic self-portraits.');

INSERT INTO artworks (title, year_created, medium, dimensions) VALUES
('Water Lilies', 1916, 'Oil on canvas', '200 cm × 180 cm'),
('The Two Fridas', 1939, 'Oil on canvas', '173 cm × 173 cm');

INSERT INTO artist_artworks (artist_id, artwork_id) VALUES
(1, 1),
(2, 2);

INSERT INTO restorations (artwork_id, restoration_date, description, cost) VALUES
(1, '2026-02-20', 'Cleaning and minor pigment stabilization', 1200.00),
(2, '2026-03-18', 'Canvas repair and protective coating', 1750.00);

INSERT INTO exhibitions (title, start_date, end_date, description) VALUES
('Impressionism Revisited', '2026-04-10', '2026-06-20', 'Exploration of impressionist works and techniques.'),
('Surreal & Symbolic', '2026-05-15', '2026-07-30', 'Art focused on symbolism and personal narratives.');

INSERT INTO exhibition_artworks (exhibition_id, artwork_id, display_order) VALUES
(1, 1, 1),
(2, 2, 1);

INSERT INTO employees (first_name, last_name, email, phone, position, hire_date) VALUES
('Emma', 'Davis', 'emma.davis@example.com', '321-654-0987', 'Curator', '2019-09-10'),
('Liam', 'Brown', 'liam.brown@example.com', '654-987-1230', 'Guide', '2022-02-14');

INSERT INTO exhibition_employees (exhibition_id, employee_id, role) VALUES
(1, 1, 'curator'),
(2, 2, 'guide');

INSERT INTO visitors (first_name, last_name, email, phone) VALUES
('Michael', 'Clark', 'michael.clark@example.com', '555-777-8888'),
('Sophie', 'Turner', 'sophie.turner@example.com', '555-999-0000');

INSERT INTO ticket_types (type_name, price) VALUES
('Standard', 18.00),
('Discount', 9.00);

INSERT INTO tickets (visitor_id, ticket_type_id, exhibition_id, purchase_date, visit_date) VALUES
(1, 1, 1, current_timestamp, '2026-04-12'),
(2, 2, 2, current_timestamp, '2026-05-20');

ALTER TABLE artists ADD COLUMN record_ts DATE NOT NULL DEFAULT (CURRENT_DATE);
ALTER TABLE artworks ADD COLUMN record_ts DATE NOT NULL DEFAULT (CURRENT_DATE);
ALTER TABLE artist_artworks ADD COLUMN record_ts DATE NOT NULL DEFAULT (CURRENT_DATE);
ALTER TABLE restorations ADD COLUMN record_ts DATE NOT NULL DEFAULT (CURRENT_DATE);
ALTER TABLE exhibitions ADD COLUMN record_ts DATE NOT NULL DEFAULT (CURRENT_DATE);
ALTER TABLE exhibition_artworks ADD COLUMN record_ts DATE NOT NULL DEFAULT (CURRENT_DATE);
ALTER TABLE employees ADD COLUMN record_ts DATE NOT NULL DEFAULT (CURRENT_DATE);
ALTER TABLE exhibition_employees ADD COLUMN record_ts DATE NOT NULL DEFAULT (CURRENT_DATE);
ALTER TABLE visitors ADD COLUMN record_ts DATE NOT NULL DEFAULT (CURRENT_DATE);
ALTER TABLE ticket_types ADD COLUMN record_ts DATE NOT NULL DEFAULT (CURRENT_DATE);
ALTER TABLE tickets ADD COLUMN record_ts DATE NOT NULL DEFAULT (CURRENT_DATE);
