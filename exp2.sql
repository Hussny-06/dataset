-- File: library_dw_schema.sql
-- Purpose: Create a Data Warehouse Star Schema for Library Management System
-- Fact table + Dimension tables for OLAP operations
-- Works with MySQL 8.x

-- ===========================
-- Drop & Create Database
-- ===========================
DROP DATABASE IF EXISTS library_dw;
CREATE DATABASE library_dw;
USE library_dw;

-- ===========================
-- DIMENSION TABLES
-- ===========================

-- Book Dimension: one record per unique book
CREATE TABLE dim_book (
  book_key INT AUTO_INCREMENT PRIMARY KEY,
  book_id INT NOT NULL,
  title VARCHAR(200),
  author VARCHAR(150),
  genre VARCHAR(50),
  publisher VARCHAR(100),
  -- Optional descriptive attributes for analysis
  publication_year INT DEFAULT NULL,
  shelf_location VARCHAR(50) DEFAULT NULL,
  UNIQUE(book_id)
);

-- Member Dimension: one record per library member
CREATE TABLE dim_member (
  member_key INT AUTO_INCREMENT PRIMARY KEY,
  member_id INT NOT NULL,
  name VARCHAR(150),
  membership_level ENUM('Basic','Silver','Gold') DEFAULT 'Basic',
  gender ENUM('M','F','O') DEFAULT 'O',
  city VARCHAR(100),
  state VARCHAR(100),
  join_date DATE,
  UNIQUE(member_id)
);

-- Date Dimension: one record per day, supports drilldown (year→quarter→month→day)
CREATE TABLE dim_date (
  date_key INT AUTO_INCREMENT PRIMARY KEY,
  full_date DATE NOT NULL,
  day INT,
  month INT,
  quarter INT,
  year INT,
  day_name VARCHAR(10),
  month_name VARCHAR(10),
  is_weekend BOOLEAN,
  UNIQUE(full_date)
);

-- ===========================
-- FACT TABLE
-- ===========================
-- The central fact table capturing borrow transactions
-- Each row = one borrow event with links to dimension tables

CREATE TABLE fact_borrow (
  borrow_key INT AUTO_INCREMENT PRIMARY KEY,
  book_key INT,
  member_key INT,
  borrow_date_key INT,
  return_date_key INT,
  copies_borrowed INT DEFAULT 1,
  borrow_duration INT,  -- e.g., DATEDIFF(return_date, borrow_date)
  fine_amount DECIMAL(6,2) DEFAULT 0.00,

  FOREIGN KEY (book_key) REFERENCES dim_book(book_key),
  FOREIGN KEY (member_key) REFERENCES dim_member(member_key),
  FOREIGN KEY (borrow_date_key) REFERENCES dim_date(date_key),
  FOREIGN KEY (return_date_key) REFERENCES dim_date(date_key)
);

-- ===========================
-- SAMPLE DIMENSION DATA
-- ===========================

INSERT INTO dim_book (book_id, title, author, genre, publisher, publication_year, shelf_location)
VALUES
(1, 'Intro to Databases', 'A. Author', 'Computer Science', 'UniPub', 2021, 'S1-A'),
(2, 'Advanced Algorithms', 'B. Writer', 'Computer Science', 'TechBooks', 2020, 'S1-B'),
(3, 'World History', 'C. Historian', 'History', 'HistPress', 2019, 'S2-A'),
(4, 'Modern Physics', 'D. Scientist', 'Science', 'ScienceHouse', 2021, 'S3-A'),
(5, 'Children Stories', 'E. Storyteller', 'Children', 'KidsPress', 2018, 'S4-A'),
(6, 'Data Warehousing', 'F. Analyst', 'Computer Science', 'UniPub', 2022, 'S1-C');

INSERT INTO dim_member (member_id, name, membership_level, gender, city, state, join_date)
VALUES
(1, 'Alice', 'Gold', 'F', 'Mumbai', 'Maharashtra', '2023-05-10'),
(2, 'Bob', 'Silver', 'M', 'Delhi', 'Delhi', '2023-06-15'),
(3, 'Carol', 'Basic', 'F', 'Bengaluru', 'Karnataka', '2023-07-01'),
(4, 'Dave', 'Gold', 'M', 'Chennai', 'Tamil Nadu', '2023-05-12'),
(5, 'Eve', 'Basic', 'F', 'Pune', 'Maharashtra', '2023-08-01');

-- Populate dim_date (a few months)
INSERT INTO dim_date (full_date, day, month, quarter, year, day_name, month_name, is_weekend)
SELECT
  DATE_ADD('2025-01-01', INTERVAL seq DAY) AS full_date,
  DAY(DATE_ADD('2025-01-01', INTERVAL seq DAY)),
  MONTH(DATE_ADD('2025-01-01', INTERVAL seq DAY)),
  QUARTER(DATE_ADD('2025-01-01', INTERVAL seq DAY)),
  YEAR(DATE_ADD('2025-01-01', INTERVAL seq DAY)),
  DAYNAME(DATE_ADD('2025-01-01', INTERVAL seq DAY)),
  MONTHNAME(DATE_ADD('2025-01-01', INTERVAL seq DAY)),
  IF(DAYOFWEEK(DATE_ADD('2025-01-01', INTERVAL seq DAY)) IN (1,7), TRUE, FALSE)
FROM (
  SELECT 0 AS seq UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4
  UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9
  UNION ALL SELECT 10 UNION ALL SELECT 11 UNION ALL SELECT 12 UNION ALL SELECT 13 UNION ALL SELECT 14
  UNION ALL SELECT 15 UNION ALL SELECT 16 UNION ALL SELECT 17 UNION ALL SELECT 18 UNION ALL SELECT 19
  UNION ALL SELECT 20 UNION ALL SELECT 21 UNION ALL SELECT 22 UNION ALL SELECT 23 UNION ALL SELECT 24
  UNION ALL SELECT 25 UNION ALL SELECT 26 UNION ALL SELECT 27 UNION ALL SELECT 28 UNION ALL SELECT 29
  UNION ALL SELECT 30 UNION ALL SELECT 31 UNION ALL SELECT 32 UNION ALL SELECT 33 UNION ALL SELECT 34
  UNION ALL SELECT 35 UNION ALL SELECT 36 UNION ALL SELECT 37 UNION ALL SELECT 38 UNION ALL SELECT 39
  UNION ALL SELECT 40 UNION ALL SELECT 41 UNION ALL SELECT 42 UNION ALL SELECT 43 UNION ALL SELECT 44
  UNION ALL SELECT 45 UNION ALL SELECT 46 UNION ALL SELECT 47 UNION ALL SELECT 48 UNION ALL SELECT 49
  UNION ALL SELECT 50 UNION ALL SELECT 51 UNION ALL SELECT 52 UNION ALL SELECT 53 UNION ALL SELECT 54
  UNION ALL SELECT 55 UNION ALL SELECT 56 UNION ALL SELECT 57 UNION ALL SELECT 58 UNION ALL SELECT 59
) AS seq_list;

-- ===========================
-- SAMPLE FACT DATA
-- (Note: in real DWH, you'd load via ETL using foreign keys from dimension tables)
-- ===========================

INSERT INTO fact_borrow (book_key, member_key, borrow_date_key, return_date_key, copies_borrowed, borrow_duration, fine_amount)
VALUES
(1, 1, 1, 5, 1, 7, 0.00),
(2, 2, 3, 8, 1, 7, 0.00),
(3, 3, 10, 15, 1, 6, 0.00),
(4, 4, 20, 25, 1, 5, 2.00),
(5, 5, 30, 40, 2, 10, 0.00),
(6, 1, 35, 45, 1, 8, 0.00);

-- ===========================
-- Verification Queries
-- ===========================
SELECT COUNT(*) AS book_dim_records FROM dim_book;
SELECT COUNT(*) AS member_dim_records FROM dim_member;
SELECT COUNT(*) AS date_dim_records FROM dim_date;
SELECT COUNT(*) AS fact_records FROM fact_borrow;

-- View star schema join (for analysis)
SELECT
  db.genre,
  dm.membership_level,
  dd.year,
  COUNT(fb.borrow_key) AS total_borrows,
  SUM(fb.copies_borrowed) AS total_copies
FROM fact_borrow fb
JOIN dim_book db ON fb.book_key = db.book_key
JOIN dim_member dm ON fb.member_key = dm.member_key
JOIN dim_date dd ON fb.borrow_date_key = dd.date_key
GROUP BY db.genre, dm.membership_level, dd.year
ORDER BY db.genre, dm.membership_level;

-- ===========================
-- End of file
-- ===========================