-- File: library_olap.sql
-- Purpose: Example schema + sample data + OLAP queries (slice, dice, rollup, drilldown)
-- Tested for MySQL 8.x (uses WITH ROLLUP and GROUPING functions)

-- Clean up if rerunning
DROP DATABASE IF EXISTS library_olap;
CREATE DATABASE library_olap;
USE library_olap;

-- ===========================
-- Dimension tables
-- ===========================
CREATE TABLE books (
  book_id INT AUTO_INCREMENT PRIMARY KEY,
  title VARCHAR(200) NOT NULL,
  author VARCHAR(150),
  genre VARCHAR(50),
  publisher VARCHAR(100)
);

CREATE TABLE members (
  member_id INT AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(150) NOT NULL,
  membership_level ENUM('Basic','Silver','Gold') DEFAULT 'Basic',
  city VARCHAR(100)
);

-- Optional: date dimension (simple)
CREATE TABLE date_dim (
  d DATE PRIMARY KEY,
  year SMALLINT,
  month TINYINT,
  day TINYINT,
  quarter TINYINT
);

-- Populate date_dim for a small range (helper insert)
INSERT INTO date_dim (d, year, month, day, quarter)
SELECT curdate() + INTERVAL seq DAY,
       YEAR(curdate() + INTERVAL seq DAY),
       MONTH(curdate() + INTERVAL seq DAY),
       DAY(curdate() + INTERVAL seq DAY),
       QUARTER(curdate() + INTERVAL seq DAY)
FROM (
  SELECT 0 AS seq UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4
  UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9
  UNION ALL SELECT 10 UNION ALL SELECT 11 UNION ALL SELECT 12 UNION ALL SELECT 13 UNION ALL SELECT 14
  UNION ALL SELECT 15 UNION ALL SELECT 16 UNION ALL SELECT 17 UNION ALL SELECT 18 UNION ALL SELECT 19
) AS nums
WHERE curdate() + INTERVAL seq DAY <= curdate() + INTERVAL 60 DAY
ON DUPLICATE KEY UPDATE year = VALUES(year);

-- ===========================
-- Fact table (borrowing transactions)
-- ===========================
CREATE TABLE borrow_facts (
  borrow_id INT AUTO_INCREMENT PRIMARY KEY,
  book_id INT NOT NULL,
  member_id INT NOT NULL,
  borrow_date DATE NOT NULL,
  return_date DATE,
  copies INT DEFAULT 1,
  FOREIGN KEY (book_id) REFERENCES books(book_id),
  FOREIGN KEY (member_id) REFERENCES members(member_id)
);

-- ===========================
-- Sample data
-- ===========================
INSERT INTO books (title, author, genre, publisher) VALUES
('Intro to Databases','A. Author','Computer Science','UniPub'),
('Advanced Algorithms','B. Writer','Computer Science','TechBooks'),
('World History','C. Historian','History','HistPress'),
('Modern Physics','D. Scientist','Science','ScienceHouse'),
('Children Stories','E. Storyteller','Children','KidsPress'),
('Data Warehousing','F. Analyst','Computer Science','UniPub');

INSERT INTO members (name, membership_level, city) VALUES
('Alice','Gold','Mumbai'),
('Bob','Silver','Delhi'),
('Carol','Basic','Bengaluru'),
('Dave','Gold','Chennai'),
('Eve','Basic','Pune');

-- Insert sample borrow transactions (mix of years & months)
INSERT INTO borrow_facts (book_id, member_id, borrow_date, return_date, copies) VALUES
(1, 1, '2024-12-28','2025-01-05', 1),
(2, 2, '2025-01-03','2025-01-10', 1),
(3, 3, '2025-02-14','2025-02-20', 1),
(4, 4, '2025-02-20','2025-03-01', 1),
(2, 1, '2025-03-02','2025-03-10', 1),
(1, 5, '2025-03-05',NULL, 1),
(6, 1, '2025-03-10','2025-03-20', 1),
(4, 2, '2025-03-11','2025-03-15', 1),
(5, 3, '2025-03-12','2025-03-20', 2),
(1, 2, '2025-04-01','2025-04-10', 1),
(3, 4, '2025-04-05','2025-04-15', 1),
(6, 5, '2025-04-07',NULL, 1);

-- Quick checks
SELECT COUNT(*) AS total_books FROM books;
SELECT COUNT(*) AS total_members FROM members;
SELECT COUNT(*) AS total_borrows FROM borrow_facts;

-- ===========================
-- OLAP operations examples
-- ===========================
-- 1) SLICE
--    Slice is selecting a single dimension value, e.g., all borrows for genre = 'Computer Science'
--    (a slice fixes one dimension value)
SELECT b.genre, COUNT(*) AS borrow_count
FROM borrow_facts bf
JOIN books b USING (book_id)
WHERE b.genre = 'Computer Science'
GROUP BY b.genre;

-- 2) DICE
--    Dice: select a subcube by applying multiple filters across dimensions
--    Example: borrows for Computer Science books in 2025 by 'Gold' members
SELECT b.genre, YEAR(bf.borrow_date) AS yr, m.membership_level, COUNT(*) AS borrow_count
FROM borrow_facts bf
JOIN books b USING (book_id)
JOIN members m USING (member_id)
WHERE b.genre = 'Computer Science'
  AND YEAR(bf.borrow_date) = 2025
  AND m.membership_level = 'Gold'
GROUP BY b.genre, YEAR(bf.borrow_date), m.membership_level;

-- 3) ROLLUP (drill-up / aggregation at multiple levels)
--    Rollup computes hierarchical aggregates: genre -> year -> grand total
SELECT
  COALESCE(b.genre, '<<ALL GENRES>>') AS genre,
  COALESCE(YEAR(bf.borrow_date), 0) AS yr,
  COUNT(*) AS borrow_count,
  GROUPING(b.genre) AS g_genre,            -- 1 when genre is aggregated in rollup
  GROUPING(YEAR(bf.borrow_date)) AS g_year -- 1 when year is aggregated
FROM borrow_facts bf
JOIN books b USING (book_id)
GROUP BY b.genre, YEAR(bf.borrow_date) WITH ROLLUP
ORDER BY
  CASE WHEN b.genre IS NULL THEN 1 ELSE 0 END,
  b.genre, YEAR(bf.borrow_date);

-- Explanation:
-- Rows where genre IS NULL are subtotals (or grand total). GROUPING() helps detect subtotal rows.

-- 4) DRILLDOWN
--    Start at a higher aggregation, then drill down to finer grains.
--    Example: first see year-level totals, then drill to month-level for a selected year.

-- 4a) Year-level totals (coarse grain)
SELECT YEAR(bf.borrow_date) AS yr, COUNT(*) AS borrow_count
FROM borrow_facts bf
GROUP BY YEAR(bf.borrow_date)
ORDER BY yr;

-- 4b) Drilldown to month-level for year 2025 (finer grain)
SELECT YEAR(bf.borrow_date) AS yr, MONTH(bf.borrow_date) AS mon, COUNT(*) AS borrow_count
FROM borrow_facts bf
WHERE YEAR(bf.borrow_date) = 2025
GROUP BY YEAR(bf.borrow_date), MONTH(bf.borrow_date)
ORDER BY mon;

-- 4c) Drill further to daily-level for March 2025 (very fine grain)
SELECT bf.borrow_date AS day, COUNT(*) AS borrow_count
FROM borrow_facts bf
WHERE YEAR(bf.borrow_date) = 2025 AND MONTH(bf.borrow_date) = 3
GROUP BY bf.borrow_date
ORDER BY bf.borrow_date;

-- 5) GROUPING SETS example (multiple aggregates in one query)
--    Show (genre, year), (genre), (year) and grand total in one shot.
SELECT
  COALESCE(b.genre, '<<ALL GENRES>>') AS genre,
  COALESCE(YEAR(bf.borrow_date), 0) AS yr,
  COUNT(*) AS borrow_count,
  GROUPING(b.genre) AS g_genre,
  GROUPING(YEAR(bf.borrow_date)) AS g_year
FROM borrow_facts bf
JOIN books b USING (book_id)
GROUP BY GROUPING SETS (
  (b.genre, YEAR(bf.borrow_date)),
  (b.genre),
  (YEAR(bf.borrow_date)),
  ()
)
ORDER BY g_genre, g_year, genre, yr;

-- ===========================
-- Useful materialized-like view (manual refresh)
-- ===========================
-- MySQL does not have native materialized views. Here is a pre-aggregated table you can refresh when needed.
DROP TABLE IF EXISTS agg_borrows_by_genre_year;
CREATE TABLE agg_borrows_by_genre_year AS
SELECT b.genre, YEAR(bf.borrow_date) AS yr, COUNT(*) AS borrow_count
FROM borrow_facts bf
JOIN books b USING (book_id)
GROUP BY b.genre, YEAR(bf.borrow_date);

SELECT * FROM agg_borrows_by_genre_year ORDER BY genre, yr;

-- If you later insert more facts, refresh via:
-- TRUNCATE TABLE agg_borrows_by_genre_year;
-- INSERT INTO agg_borrows_by_genre_year SELECT b.genre, YEAR(bf.borrow_date), COUNT(*) FROM borrow_facts bf JOIN books b USING(book_id) GROUP BY b.genre, YEAR(bf.borrow_date);

-- ===========================
-- End of script
-- ===========================