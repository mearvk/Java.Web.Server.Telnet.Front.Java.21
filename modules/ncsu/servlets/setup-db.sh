#!/bin/bash
set -e
# SAFE: Uses CREATE IF NOT EXISTS. Never drops or overwrites existing data.
# Can be run repeatedly after git pull without risk to production databases.
echo "[*] Creating nwe_ncsu database..."
mysql -u root -e "
CREATE DATABASE IF NOT EXISTS nwe_ncsu;
USE nwe_ncsu;

CREATE TABLE IF NOT EXISTS college_queries (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    college VARCHAR(200) NOT NULL,
    query_text TEXT NOT NULL,
    status ENUM('pending','answered','archived') DEFAULT 'pending',
    installer_id VARCHAR(64) DEFAULT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_college (college), INDEX idx_status (status)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS course_catalog (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    college VARCHAR(200) NOT NULL,
    department VARCHAR(200),
    course_code VARCHAR(20),
    title VARCHAR(500),
    description TEXT,
    credits INT DEFAULT 3,
    installer_id VARCHAR(64) DEFAULT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_college (college), INDEX idx_dept (department), INDEX idx_code (course_code)
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
    college VARCHAR(200) NOT NULL,
    department_name VARCHAR(200) NOT NULL,
    head VARCHAR(200),
    url VARCHAR(500),
    installer_id VARCHAR(64) DEFAULT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_college (college)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Seed administration data
INSERT IGNORE INTO administration (id, title, name, department) VALUES
(1, 'Chancellor', 'Kevin M. Guskiewicz', 'Office of the Chancellor'),
(2, 'Provost and Executive Vice Chancellor', 'Warwick Arden', 'Office of the Provost'),
(3, 'Vice Chancellor for Research and Innovation', 'Mladen Vouk', 'Office of Research and Innovation'),
(4, 'Vice Chancellor for Student Affairs', 'Doneka Scott', 'Division of Academic and Student Affairs'),
(5, 'Vice Chancellor for Finance and Administration', 'Charles Leffler', 'Finance and Administration'),
(6, 'Vice Chancellor for University Advancement', 'Brian Sischo', 'University Advancement'),
(7, 'Vice Chancellor for Information Technology', 'Marc Hoit', 'Office of Information Technology'),
(8, 'Dean of Engineering', 'Louis Martin-Vega', 'College of Engineering'),
(9, 'Dean of Sciences', 'Christopher McGahan', 'College of Sciences'),
(10, 'Dean of Agriculture and Life Sciences', 'Richard Linton', 'College of Agriculture and Life Sciences'),
(11, 'Athletics Director', 'Boo Corrigan', 'Athletics'),
(12, 'Faculty Senate Chair', 'RaJade M. Berry-James', 'Faculty Senate');

-- Seed departments
INSERT IGNORE INTO departments (id, college, department_name) VALUES
(1, 'College of Engineering', 'Biomedical Engineering'),
(2, 'College of Engineering', 'Chemical and Biomolecular Engineering'),
(3, 'College of Engineering', 'Civil, Construction, and Environmental Engineering'),
(4, 'College of Engineering', 'Computer Science'),
(5, 'College of Engineering', 'Electrical and Computer Engineering'),
(6, 'College of Engineering', 'Industrial and Systems Engineering'),
(7, 'College of Engineering', 'Materials Science and Engineering'),
(8, 'College of Engineering', 'Mechanical and Aerospace Engineering'),
(9, 'College of Engineering', 'Nuclear Engineering'),
(10, 'College of Sciences', 'Biological Sciences'),
(11, 'College of Sciences', 'Chemistry'),
(12, 'College of Sciences', 'Marine, Earth, and Atmospheric Sciences'),
(13, 'College of Sciences', 'Mathematics'),
(14, 'College of Sciences', 'Physics'),
(15, 'College of Sciences', 'Statistics'),
(16, 'Poole College of Management', 'Accounting'),
(17, 'Poole College of Management', 'Business Management'),
(18, 'Poole College of Management', 'Economics'),
(19, 'Poole College of Management', 'Finance'),
(20, 'Poole College of Management', 'Marketing'),
(21, 'College of Design', 'Architecture'),
(22, 'College of Design', 'Art + Design'),
(23, 'College of Design', 'Graphic Design'),
(24, 'College of Design', 'Industrial Design'),
(25, 'College of Design', 'Landscape Architecture'),
(26, 'College of Agriculture and Life Sciences', 'Animal Science'),
(27, 'College of Agriculture and Life Sciences', 'Crop and Soil Sciences'),
(28, 'College of Agriculture and Life Sciences', 'Biological and Agricultural Engineering'),
(29, 'College of Agriculture and Life Sciences', 'Horticultural Science'),
(30, 'College of Agriculture and Life Sciences', 'Food, Bioprocessing and Nutrition Sciences'),
(31, 'College of Veterinary Medicine', 'Clinical Sciences'),
(32, 'College of Veterinary Medicine', 'Molecular Biomedical Sciences'),
(33, 'College of Veterinary Medicine', 'Population Health and Pathobiology'),
(34, 'Wilson College of Textiles', 'Textile and Apparel, Technology and Management'),
(35, 'Wilson College of Textiles', 'Textile Engineering, Chemistry and Science'),
(36, 'College of Humanities and Social Sciences', 'Communication'),
(37, 'College of Humanities and Social Sciences', 'English'),
(38, 'College of Humanities and Social Sciences', 'History'),
(39, 'College of Humanities and Social Sciences', 'Political Science'),
(40, 'College of Humanities and Social Sciences', 'Psychology'),
(41, 'College of Humanities and Social Sciences', 'Sociology and Anthropology'),
(42, 'College of Education', 'Teacher Education and Learning Sciences'),
(43, 'College of Education', 'STEM Education'),
(44, 'College of Natural Resources', 'Forestry and Environmental Resources'),
(45, 'College of Natural Resources', 'Parks, Recreation and Tourism Management');
"
echo "[OK] nwe_ncsu database ready."
