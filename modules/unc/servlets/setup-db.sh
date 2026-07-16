#!/bin/bash
set -e
# SAFE: Uses CREATE IF NOT EXISTS. Never drops or overwrites existing data.
echo "[*] Creating nwe_unc database..."
mysql -u root -e "
CREATE DATABASE IF NOT EXISTS nwe_unc;
USE nwe_unc;

CREATE TABLE IF NOT EXISTS school_queries (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    school VARCHAR(200) NOT NULL,
    query_text TEXT NOT NULL,
    status ENUM('pending','answered','archived') DEFAULT 'pending',
    installer_id VARCHAR(64) DEFAULT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_school (school), INDEX idx_status (status)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS course_catalog (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    school VARCHAR(200) NOT NULL,
    department VARCHAR(200),
    course_code VARCHAR(20),
    title VARCHAR(500),
    description TEXT,
    credits INT DEFAULT 3,
    installer_id VARCHAR(64) DEFAULT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_school (school), INDEX idx_dept (department), INDEX idx_code (course_code)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS administration (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    title VARCHAR(200) NOT NULL,
    name VARCHAR(200) NOT NULL,
    department VARCHAR(200),
    email VARCHAR(200),
    phone VARCHAR(50),
    installer_id VARCHAR(64) DEFAULT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_title (title), INDEX idx_dept (department)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS departments (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    school VARCHAR(200) NOT NULL,
    department_name VARCHAR(200) NOT NULL,
    head VARCHAR(200),
    url VARCHAR(500),
    installer_id VARCHAR(64) DEFAULT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_school (school)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Seed administration data
INSERT IGNORE INTO administration (id, title, name, department) VALUES
(1, 'Chancellor', 'Lee H. Roberts', 'Office of the Chancellor'),
(2, 'Provost and Chief Academic Officer', 'Christopher Clemens', 'Office of the Provost'),
(3, 'Executive Vice Chancellor and Provost', 'Robert A. Blouin', 'Office of the Provost'),
(4, 'Vice Chancellor for Research', 'Penny Gordon-Larsen', 'Office of the Vice Chancellor for Research'),
(5, 'Vice Chancellor for Student Affairs', 'Amy Johnson', 'Division of Student Affairs'),
(6, 'Vice Chancellor for Finance and Operations', 'Nate Knuffman', 'Finance and Operations'),
(7, 'Vice Chancellor for University Development', 'David Routh', 'University Development'),
(8, 'Vice Chancellor for IT and CIO', 'Chris Kielt', 'Information Technology Services'),
(9, 'Dean of Arts and Sciences', 'Terry Rhodes', 'College of Arts and Sciences'),
(10, 'Dean of Kenan-Flagler Business School', 'Mary-Ann Fitzgerald', 'Kenan-Flagler Business School'),
(11, 'Dean of School of Medicine', 'Wesley Burks', 'School of Medicine'),
(12, 'Athletics Director', 'Bubba Cunningham', 'Athletics'),
(13, 'Faculty Chair', 'Mimi Chapman', 'Faculty Council');

-- Seed departments
INSERT IGNORE INTO departments (id, school, department_name) VALUES
(1, 'College of Arts and Sciences', 'African, African American, and Diaspora Studies'),
(2, 'College of Arts and Sciences', 'American Studies'),
(3, 'College of Arts and Sciences', 'Anthropology'),
(4, 'College of Arts and Sciences', 'Art and Art History'),
(5, 'College of Arts and Sciences', 'Biology'),
(6, 'College of Arts and Sciences', 'Chemistry'),
(7, 'College of Arts and Sciences', 'Classics'),
(8, 'College of Arts and Sciences', 'Communication'),
(9, 'College of Arts and Sciences', 'Computer Science'),
(10, 'College of Arts and Sciences', 'Economics'),
(11, 'College of Arts and Sciences', 'English and Comparative Literature'),
(12, 'College of Arts and Sciences', 'Geography'),
(13, 'College of Arts and Sciences', 'History'),
(14, 'College of Arts and Sciences', 'Linguistics'),
(15, 'College of Arts and Sciences', 'Mathematics'),
(16, 'College of Arts and Sciences', 'Music'),
(17, 'College of Arts and Sciences', 'Philosophy'),
(18, 'College of Arts and Sciences', 'Physics and Astronomy'),
(19, 'College of Arts and Sciences', 'Political Science'),
(20, 'College of Arts and Sciences', 'Psychology and Neuroscience'),
(21, 'College of Arts and Sciences', 'Religious Studies'),
(22, 'College of Arts and Sciences', 'Sociology'),
(23, 'College of Arts and Sciences', 'Statistics and Operations Research'),
(24, 'Kenan-Flagler Business School', 'Accounting'),
(25, 'Kenan-Flagler Business School', 'Finance'),
(26, 'Kenan-Flagler Business School', 'Marketing'),
(27, 'Kenan-Flagler Business School', 'Operations'),
(28, 'Kenan-Flagler Business School', 'Strategy and Entrepreneurship'),
(29, 'School of Medicine', 'Anesthesiology'),
(30, 'School of Medicine', 'Biochemistry and Biophysics'),
(31, 'School of Medicine', 'Cell Biology and Physiology'),
(32, 'School of Medicine', 'Dermatology'),
(33, 'School of Medicine', 'Emergency Medicine'),
(34, 'School of Medicine', 'Family Medicine'),
(35, 'School of Medicine', 'Genetics'),
(36, 'School of Medicine', 'Internal Medicine'),
(37, 'School of Medicine', 'Neurology'),
(38, 'School of Medicine', 'Pediatrics'),
(39, 'School of Medicine', 'Psychiatry'),
(40, 'School of Medicine', 'Surgery'),
(41, 'Gillings School of Global Public Health', 'Biostatistics'),
(42, 'Gillings School of Global Public Health', 'Epidemiology'),
(43, 'Gillings School of Global Public Health', 'Health Policy and Management'),
(44, 'Gillings School of Global Public Health', 'Nutrition'),
(45, 'Hussman School of Journalism and Media', 'Journalism'),
(46, 'Hussman School of Journalism and Media', 'Advertising and Public Relations'),
(47, 'School of Education', 'Educational Leadership'),
(48, 'School of Education', 'Human Development and Family Studies'),
(49, 'School of Information and Library Science', 'Information Science'),
(50, 'School of Information and Library Science', 'Library Science');
"
echo "[OK] nwe_unc database ready."
