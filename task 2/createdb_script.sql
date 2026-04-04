-- create database gallery;

create schema if not exists gallery;
set search_path = gallery;

create table if not exists artists (
    artist_id int generated always as identity primary key,
    first_name varchar(100) not null,
    last_name varchar(100) not null,
    birth_date date,
    death_date date,
    nationality varchar(100),
    biography text
);

create table if not exists artworks (
    artwork_id int generated always as identity primary key,
    title varchar(200) not null,
    year_created int,
    medium varchar(100),
    dimensions varchar(100)
);

-- artists and artworks many-to-many bridge
create table if not exists artist_artworks (
    artist_id int,
    artwork_id int,
    primary key (artist_id, artwork_id),
    foreign key (artist_id) references artists(artist_id),
    foreign key (artwork_id) references artworks(artwork_id)
);

create table if not exists restorations (
    restoration_id int generated always as identity primary key,
    artwork_id int not null,
    restoration_date date not null,
    description text,
    cost decimal(10,2) not null,
    foreign key (artwork_id) references artworks(artwork_id),
    check (restoration_date > date '2026-01-01'),
    check (cost >= 0) -- prevent negative values
);

create table if not exists exhibitions (
    exhibition_id int generated always as identity primary key,
    title varchar(200) not null unique,
    start_date date not null,
    end_date date,
    description text,
    check (start_date > date '2026-01-01')
);

-- exhibition and artworks many-to-many bridge
create table if not exists exhibition_artworks (
    exhibition_id int,
    artwork_id int,
    display_order int,
    primary key (exhibition_id, artwork_id),
    foreign key (exhibition_id) references exhibitions(exhibition_id),
    foreign key (artwork_id) references artworks(artwork_id)
);

create table if not exists employees (
    employee_id int generated always as identity primary key,
    first_name varchar(100) not null,
    last_name varchar(100) not null,
    email varchar(150) unique,
    phone varchar(30),
    position varchar(100) not null,
    hire_date date
);

-- exhibition and employees many-to-many bridge
create table if not exists exhibition_employees (
    exhibition_id int,
    employee_id int,
    role varchar(100) not null,
    primary key (exhibition_id, employee_id),
    foreign key (exhibition_id) references exhibitions(exhibition_id),
    foreign key (employee_id) references employees(employee_id),
    check (role in ('curator','manager','guide'))
);

create table if not exists visitors (
    visitor_id int generated always as identity primary key,
    first_name varchar(100) not null,
    last_name varchar(100) not null,
    email varchar(150) unique,
    phone varchar(30)
);

create table if not exists ticket_types (
    ticket_type_id int generated always as identity primary key,
    type_name varchar(50) not null unique,
    price decimal(8,2) not null,
    check (price >= 0)
);

create table if not exists tickets (
    ticket_id int generated always as identity primary key,
    visitor_id int not null,
    ticket_type_id int not null,
    exhibition_id int not null,
    purchase_date timestamp not null default current_timestamp,
    visit_date date not null,
    foreign key (visitor_id) references visitors(visitor_id),
    foreign key (ticket_type_id) references ticket_types(ticket_type_id),
    foreign key (exhibition_id) references exhibitions(exhibition_id),
    check (visit_date > date '2026-01-01')
);
