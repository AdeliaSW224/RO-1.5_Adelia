-- ============================================================
-- Assignment 3: DCL & DML — DCL DML
-- File: adelia_umbetalieva_a3.sql
-- Schema: gallery 
-- Re-runnable: cleanup at top, truncate before inserts
-- ============================================================

set search_path = gallery;


do $$
begin
    if exists (select 1 from pg_roles where rolname = 'db_admin_user') then
        execute 'revoke gallery_admin from db_admin_user';
    end if;
    if exists (select 1 from pg_roles where rolname = 'db_reader_user') then
        execute 'revoke gallery_readonly from db_reader_user';
    end if;
end
$$;

drop user  if exists db_admin_user;
drop user  if exists db_reader_user;
drop role  if exists gallery_admin;
drop role  if exists gallery_readonly;



-- A1 — Create two roles with correct privileges


create role gallery_admin;
create role gallery_readonly;

grant usage on schema gallery to gallery_admin;
grant usage on schema gallery to gallery_readonly;

grant select, insert, update, delete
    on all tables in schema gallery to gallery_admin;

grant select
    on all tables in schema gallery to gallery_readonly;


-- A2 — Create two users and assign roles

create user db_admin_user  with password 'AdminPass!2026';
create user db_reader_user with password 'ReaderPass!2026';

grant gallery_admin    to db_admin_user;
grant gallery_readonly to db_reader_user;


-- A3 — Revoke UPDATE and DELETE from readonly role (safety net)

revoke update, delete on all tables in schema gallery from gallery_readonly;

/*
  Output of: \dp gallery.tickets

                                    Access privileges
  Schema  |  Name   | Type  |         Access privileges
  --------+---------+-------+------------------------------------
  gallery | tickets | table | postgres=arwdDxtm/postgres         +
          |         |       | gallery_admin=arwd/postgres        +
          |         |       | gallery_readonly=r/postgres

  gallery_readonly shows only "r" (SELECT).
  No "w" (UPDATE) or "d" (DELETE) — REVOKE confirmed.
*/

-- A3a — Verify db_admin_user (all DML should succeed)

set role db_admin_user;
select current_user;                                  -- should print: db_admin_user
select count(*) from gallery.ticket_types;            -- should succeed

insert into gallery.ticket_types (type_name, price)
values ('role_test_vip', 9999.00)
returning *;                                          -- should succeed

update gallery.ticket_types
    set price = price
    where type_name = 'role_test_vip';               -- should succeed

delete from gallery.ticket_types
    where ticket_type_id = (
        select max(ticket_type_id) from gallery.ticket_types
    );                                                -- should succeed

reset role;

-- A3a — Verify db_reader_user (only SELECT should succeed)

set role db_reader_user;
select current_user;                                  -- should print: db_reader_user
select count(*) from gallery.ticket_types;            -- should succeed

-- INSERT — expected to FAIL
begin;
insert into gallery.ticket_types (type_name, price) values ('blocked', 0.00);
-- ERROR:  permission denied for table ticket_types
rollback;

-- UPDATE — expected to FAIL
begin;
update gallery.ticket_types set price = price;
-- ERROR:  permission denied for table ticket_types
rollback;

-- DELETE — expected to FAIL
begin;
delete from gallery.ticket_types where ticket_type_id = 1;
-- ERROR:  permission denied for table ticket_types
rollback;

reset role;

-- B5 — TRUNCATE in correct FK order (children before parents)

truncate table gallery.tickets               restart identity cascade;
truncate table gallery.exhibition_employees  restart identity cascade;
truncate table gallery.exhibition_artworks   restart identity cascade;
truncate table gallery.artist_artworks       restart identity cascade;
truncate table gallery.restorations          restart identity cascade;
truncate table gallery.visitors              restart identity cascade;
truncate table gallery.ticket_types          restart identity cascade;
truncate table gallery.exhibitions           restart identity cascade;
truncate table gallery.employees             restart identity cascade;
truncate table gallery.artworks              restart identity cascade;
truncate table gallery.artists               restart identity cascade;


-- B6 — INSERT realistic data (5+ rows per table)

-- artists
insert into gallery.artists (first_name, last_name, birth_date, death_date, nationality, biography) values
    ('Leonardo',  'da Vinci',  '1452-04-15', '1519-05-02', 'Italian',
     'Renaissance polymath renowned for the Mona Lisa and meticulous anatomical studies.'),
    ('Rembrandt', 'van Rijn',  '1606-07-15', '1669-10-04', 'Dutch',
     'Baroque master celebrated for dramatic use of light and shadow in portraiture.'),
    ('Frida',     'Kahlo',     '1907-07-06', '1954-07-13', 'Mexican',
     'Surrealist known for deeply personal self-portraits fusing biography and symbolism.'),
    ('Claude',    'Monet',     '1840-11-14', '1926-12-05', 'French',
     'Father of Impressionism; dedicated decades to his Water Lilies series at Giverny.'),
    ('Kazimir',   'Malevich',  '1879-02-23', '1935-05-15', 'Russian',
     'Pioneer of Suprematism; reduced art to pure geometric form with Black Square.');

-- artworks
insert into gallery.artworks (title, year_created, medium, dimensions) values
    ('The Night Watch',                   1642, 'Oil on canvas',     '363 cm × 437 cm'),
    ('Water Lilies — Dusk',               1916, 'Oil on canvas',     '200 cm × 600 cm'),
    ('Self-Portrait with Thorn Necklace', 1940, 'Oil on canvas',     '47 cm × 38 cm'),
    ('Black Square',                      1915, 'Oil on linen',      '79.5 cm × 79.5 cm'),
    ('Vitruvian Man',                     1490, 'Ink and watercolour','34.6 cm × 25.5 cm'),
    ('The Jewish Bride',                  1667, 'Oil on canvas',     '121.5 cm × 166.5 cm'),
    ('The Two Fridas',                    1939, 'Oil on canvas',     '173.5 cm × 173 cm');

-- artist_artworks (many-to-many bridge — subqueries, no hardcoded IDs)
insert into gallery.artist_artworks (artist_id, artwork_id) values
    (
        (select artist_id from gallery.artists where last_name = 'van Rijn'  and first_name = 'Rembrandt'),
        (select artwork_id from gallery.artworks where title = 'The Night Watch')
    ),
    (
        (select artist_id from gallery.artists where last_name = 'Monet'),
        (select artwork_id from gallery.artworks where title = 'Water Lilies — Dusk')
    ),
    (
        (select artist_id from gallery.artists where last_name = 'Kahlo'),
        (select artwork_id from gallery.artworks where title = 'Self-Portrait with Thorn Necklace')
    ),
    (
        (select artist_id from gallery.artists where last_name = 'Malevich'),
        (select artwork_id from gallery.artworks where title = 'Black Square')
    ),
    (
        (select artist_id from gallery.artists where last_name = 'da Vinci'),
        (select artwork_id from gallery.artworks where title = 'Vitruvian Man')
    ),
    (
        (select artist_id from gallery.artists where last_name = 'van Rijn'  and first_name = 'Rembrandt'),
        (select artwork_id from gallery.artworks where title = 'The Jewish Bride')
    ),
    (
        (select artist_id from gallery.artists where last_name = 'Kahlo'),
        (select artwork_id from gallery.artworks where title = 'The Two Fridas')
    );

-- restorations (restoration_date must be > 2026-01-01 per CHECK constraint)
insert into gallery.restorations (artwork_id, restoration_date, description, cost) values
    (
        (select artwork_id from gallery.artworks where title = 'The Night Watch'),
        '2026-02-10',
        'Varnish removal and canvas stabilisation on lower-left quadrant.',
        125000.00
    ),
    (
        (select artwork_id from gallery.artworks where title = 'Water Lilies — Dusk'),
        '2026-03-05',
        'Inpainting of hairline cracks across the upper centre section.',
        43500.00
    ),
    (
        (select artwork_id from gallery.artworks where title = 'Black Square'),
        '2026-04-18',
        'Structural reinforcement of the degraded linen support.',
        31200.00
    ),
    (
        (select artwork_id from gallery.artworks where title = 'Vitruvian Man'),
        '2026-05-02',
        'Humidity-damage repair and paper flattening under controlled pressure.',
        18750.00
    ),
    (
        (select artwork_id from gallery.artworks where title = 'The Two Fridas'),
        '2026-06-15',
        'Surface cleaning and consolidation of flaking paint along canvas edges.',
        52000.00
    );

-- exhibitions (start_date must be > 2026-01-01 per CHECK constraint)
insert into gallery.exhibitions (title, start_date, end_date, description) values
    ('Masters of Light',           '2026-02-01', '2026-04-30',
     'Baroque and Impressionist works exploring the drama of natural and artificial light.'),
    ('Geometry & Soul',            '2026-03-15', '2026-06-15',
     'From Suprematism to Constructivism — the power of pure geometric form.'),
    ('Frida & Her World',          '2026-04-01', '2026-07-31',
     'Personal and political imagery throughout Frida Kahlo''s remarkable career.'),
    ('Renaissance Drawings',       '2026-05-20', '2026-08-20',
     'Studies and sketches by Italian Renaissance masters on paper and vellum.'),
    ('Dutch Golden Age Portraits', '2026-07-01', '2026-10-01',
     'Civic and domestic portraiture from 17th-century Holland at its cultural peak.');

-- exhibition_artworks (many-to-many bridge)
insert into gallery.exhibition_artworks (exhibition_id, artwork_id, display_order) values
    (
        (select exhibition_id from gallery.exhibitions where title = 'Masters of Light'),
        (select artwork_id    from gallery.artworks    where title = 'The Night Watch'),
        1
    ),
    (
        (select exhibition_id from gallery.exhibitions where title = 'Masters of Light'),
        (select artwork_id    from gallery.artworks    where title = 'Water Lilies — Dusk'),
        2
    ),
    (
        (select exhibition_id from gallery.exhibitions where title = 'Geometry & Soul'),
        (select artwork_id    from gallery.artworks    where title = 'Black Square'),
        1
    ),
    (
        (select exhibition_id from gallery.exhibitions where title = 'Frida & Her World'),
        (select artwork_id    from gallery.artworks    where title = 'Self-Portrait with Thorn Necklace'),
        1
    ),
    (
        (select exhibition_id from gallery.exhibitions where title = 'Frida & Her World'),
        (select artwork_id    from gallery.artworks    where title = 'The Two Fridas'),
        2
    ),
    (
        (select exhibition_id from gallery.exhibitions where title = 'Renaissance Drawings'),
        (select artwork_id    from gallery.artworks    where title = 'Vitruvian Man'),
        1
    ),
    (
        (select exhibition_id from gallery.exhibitions where title = 'Dutch Golden Age Portraits'),
        (select artwork_id    from gallery.artworks    where title = 'The Jewish Bride'),
        1
    );

-- employees
insert into gallery.employees (first_name, last_name, email, phone, position, hire_date) values
    ('Aisha',    'Bekova',      'a.bekova@gallery.kz',     '+7 701 111 2233', 'curator', '2021-03-15'),
    ('Dmitri',   'Volkov',      'd.volkov@gallery.kz',     '+7 701 222 3344', 'manager', '2019-07-01'),
    ('Saltanat', 'Nurlanovna',  's.nurlanovna@gallery.kz', '+7 702 333 4455', 'guide',   '2023-01-10'),
    ('Erik',     'Janssen',     'e.janssen@gallery.kz',    '+7 705 444 5566', 'curator', '2020-09-20'),
    ('Madina',   'Seitkali',    'm.seitkali@gallery.kz',   '+7 707 555 6677', 'guide',   '2024-02-28');

-- exhibition_employees (role CHECK: 'curator' | 'manager' | 'guide')
insert into gallery.exhibition_employees (exhibition_id, employee_id, role) values
    (
        (select exhibition_id from gallery.exhibitions where title = 'Masters of Light'),
        (select employee_id   from gallery.employees   where email = 'a.bekova@gallery.kz'),
        'curator'
    ),
    (
        (select exhibition_id from gallery.exhibitions where title = 'Masters of Light'),
        (select employee_id   from gallery.employees   where email = 'd.volkov@gallery.kz'),
        'manager'
    ),
    (
        (select exhibition_id from gallery.exhibitions where title = 'Geometry & Soul'),
        (select employee_id   from gallery.employees   where email = 'e.janssen@gallery.kz'),
        'curator'
    ),
    (
        (select exhibition_id from gallery.exhibitions where title = 'Frida & Her World'),
        (select employee_id   from gallery.employees   where email = 's.nurlanovna@gallery.kz'),
        'guide'
    ),
    (
        (select exhibition_id from gallery.exhibitions where title = 'Renaissance Drawings'),
        (select employee_id   from gallery.employees   where email = 'm.seitkali@gallery.kz'),
        'guide'
    );

-- visitors
insert into gallery.visitors (first_name, last_name, email, phone) values
    ('Aliya',   'Seitkali',     'aliya.s@mail.kz',      '+7 701 601 1111'),
    ('Nurlan',  'Abenov',       'nurlan.a@mail.kz',     '+7 702 602 2222'),
    ('Sophie',  'Müller',       'sophie.m@gmail.com',   '+49 151 123 4567'),
    ('James',   'Okafor',       'james.o@yahoo.com',    '+1 415 234 5678'),
    ('Zarina',  'Dzhaksybekov', 'z.djaks@inbox.kz',     '+7 705 605 5555');

-- ticket_types
insert into gallery.ticket_types (type_name, price) values
    ('adult',         2500.00),
    ('student',       1200.00),
    ('senior',        1500.00),
    ('child',          600.00),
    ('family_bundle', 5500.00);

-- tickets (visit_date must be > 2026-01-01 per CHECK constraint)
insert into gallery.tickets (visitor_id, ticket_type_id, exhibition_id, visit_date) values
    (
        (select visitor_id     from gallery.visitors     where email = 'aliya.s@mail.kz'),
        (select ticket_type_id from gallery.ticket_types where type_name = 'adult'),
        (select exhibition_id  from gallery.exhibitions  where title = 'Masters of Light'),
        '2026-03-10'
    ),
    (
        (select visitor_id     from gallery.visitors     where email = 'nurlan.a@mail.kz'),
        (select ticket_type_id from gallery.ticket_types where type_name = 'student'),
        (select exhibition_id  from gallery.exhibitions  where title = 'Geometry & Soul'),
        '2026-04-05'
    ),
    (
        (select visitor_id     from gallery.visitors     where email = 'sophie.m@gmail.com'),
        (select ticket_type_id from gallery.ticket_types where type_name = 'adult'),
        (select exhibition_id  from gallery.exhibitions  where title = 'Frida & Her World'),
        '2026-05-15'
    ),
    (
        (select visitor_id     from gallery.visitors     where email = 'james.o@yahoo.com'),
        (select ticket_type_id from gallery.ticket_types where type_name = 'family_bundle'),
        (select exhibition_id  from gallery.exhibitions  where title = 'Dutch Golden Age Portraits'),
        '2026-08-20'
    ),
    (
        (select visitor_id     from gallery.visitors     where email = 'z.djaks@inbox.kz'),
        (select ticket_type_id from gallery.ticket_types where type_name = 'senior'),
        (select exhibition_id  from gallery.exhibitions  where title = 'Renaissance Drawings'),
        '2026-06-01'
    );


-- ============================================================
-- PART C — DML: UPDATE
-- ============================================================

-- C7 — Update 1 (business event: visitor changed their contact phone number)
-- Preview rows that will be affected:
select visitor_id, first_name, last_name, phone
from gallery.visitors
where email = 'aliya.s@mail.kz';
-- 1 row

update gallery.visitors
    set phone = '+7 701 999 0000'
    where email = 'aliya.s@mail.kz';


-- C7 — Update 2 (business event: student ticket price raised for the new season)
-- Preview rows that will be affected:
select ticket_type_id, type_name, price
from gallery.ticket_types
where type_name = 'student';
-- 1 row

update gallery.ticket_types
    set price = 1400.00
    where type_name = 'student';


-- C8 — UPDATE ... FROM (join-based update)
-- Business event: restoration budgets for artworks currently displayed in
-- 'Masters of Light' are increased by 10 % due to higher visitor traffic
-- and additional conservation needs identified during the exhibition run.

-- Preview rows that will be affected:
select r.restoration_id,
       a.title,
       r.cost as current_cost,
       round(r.cost * 1.10, 2) as new_cost
from gallery.restorations          r
join gallery.artworks              a  on a.artwork_id    = r.artwork_id
join gallery.exhibition_artworks  ea  on ea.artwork_id   = a.artwork_id
join gallery.exhibitions           e  on e.exhibition_id = ea.exhibition_id
where e.title = 'Masters of Light';
-- 2 rows (The Night Watch, Water Lilies — Dusk)

update gallery.restorations as r
    set cost = round(r.cost * 1.10, 2)
    from gallery.exhibition_artworks  ea
    join gallery.exhibitions           e on e.exhibition_id = ea.exhibition_id
    where ea.artwork_id = r.artwork_id
      and e.title = 'Masters of Light';

-- PART D — DML: DELETE

-- D10 — Business reason:
-- Tickets purchased for exhibitions whose end_date has already passed are
-- no longer operationally relevant. Per the gallery's data-retention policy,
-- these expired ticket records are removed from the live tickets table.
-- In production they would first be copied to an archive table.

-- Preview: how many expired tickets exist before the delete?
select count(*)
from gallery.tickets     t
join gallery.exhibitions e on e.exhibition_id = t.exhibition_id
where e.end_date < current_date;
-- paste actual count here after running, e.g.: -- 0

-- D9 — DELETE inside a transaction (ROLLBACK keeps data intact for exam)
begin;

delete from gallery.tickets
    where ticket_id in (
        select t.ticket_id
        from gallery.tickets     t
        join gallery.exhibitions e on e.exhibition_id = t.exhibition_id
        where e.end_date < current_date
    );

select count(*) from gallery.tickets;

rollback;
-- safe rollback — no permanent changes made