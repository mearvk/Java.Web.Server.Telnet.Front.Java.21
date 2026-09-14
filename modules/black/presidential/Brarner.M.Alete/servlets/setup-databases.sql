-- Brarner.M.Alete Database Setup: Postal, Art, Science
-- Run as root: mysql -u root < setup-databases.sql

-- ============================================================
-- POSTAL DATABASE
-- ============================================================
CREATE DATABASE IF NOT EXISTS BrarnerPostal;
USE BrarnerPostal;

CREATE TABLE IF NOT EXISTS postal_offices (
    id INT AUTO_INCREMENT PRIMARY KEY,
    office_name VARCHAR(255) NOT NULL,
    city VARCHAR(100) NOT NULL,
    zip_code VARCHAR(10),
    county VARCHAR(100),
    status VARCHAR(20) DEFAULT 'receiving',
    port INT
);

CREATE TABLE IF NOT EXISTS experiments (
    id INT AUTO_INCREMENT PRIMARY KEY,
    office_city VARCHAR(100) NOT NULL,
    experiment_name VARCHAR(255) NOT NULL,
    experiment_data TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Seed active postal offices from config
INSERT IGNORE INTO postal_offices (office_name, city, zip_code, county, port, status) VALUES
('Charlotte Main Post Office', 'charlotte', '28201', 'Mecklenburg', 9000, 'receiving'),
('Greensboro Main Post Office', 'greensboro', '27401', 'Guilford', 9001, 'receiving'),
('Raleigh Main Post Office', 'raleigh', '27601', 'Wake', 9002, 'receiving'),
('Charlotte 002 Post Office', 'charlotte002', '28202', 'Mecklenburg', 9003, 'receiving'),
('Raleigh 002 Post Office', 'raleigh002', '27602', 'Wake', 9004, 'receiving'),
('Greensboro 002 Post Office', 'greensboro002', '27402', 'Guilford', 9005, 'receiving'),
('Durham Main Post Office', 'durham', '27701', 'Durham', 9006, 'receiving'),
('Winston-Salem Main Post Office', 'winstonsalem', '27101', 'Forsyth', 9007, 'receiving'),
('Fayetteville Main Post Office', 'fayetteville', '28301', 'Cumberland', 9008, 'receiving'),
('Asheville Main Post Office', 'asheville', '28801', 'Buncombe', 9009, 'receiving'),
('Wilmington Main Post Office', 'wilmington', '28401', 'New Hanover', 9010, 'receiving');

-- ============================================================
-- ART DATABASE
-- ============================================================
CREATE DATABASE IF NOT EXISTS BrarnerArt;
USE BrarnerArt;

CREATE TABLE IF NOT EXISTS art_institutions (
    id INT AUTO_INCREMENT PRIMARY KEY,
    institution_key VARCHAR(100) UNIQUE NOT NULL,
    name VARCHAR(255) NOT NULL,
    city VARCHAR(100),
    type VARCHAR(50) DEFAULT 'museum',
    address VARCHAR(255),
    description TEXT,
    status VARCHAR(20) DEFAULT 'receiving',
    port INT
);

CREATE TABLE IF NOT EXISTS art_collection (
    id INT AUTO_INCREMENT PRIMARY KEY,
    institution_key VARCHAR(100) NOT NULL,
    title VARCHAR(255) NOT NULL,
    artist VARCHAR(255),
    medium VARCHAR(100),
    year_created VARCHAR(20),
    description TEXT
);

-- Seed art institutions from config
INSERT IGNORE INTO art_institutions (institution_key, name, city, port, status) VALUES
('northcarolinamuseumofart', 'North Carolina Museum of Art', 'Raleigh', 18400, 'receiving'),
('acklandartmuseum', 'Ackland Art Museum', 'Chapel Hill', 18401, 'receiving'),
('adgallery', 'AD Gallery', 'Raleigh', 18402, 'receiving'),
('africanamericanatelier', 'African American Atelier', 'Greensboro', 18403, 'receiving'),
('harveybganttcenterforafricanamericanarts', 'Harvey B. Gantt Center for African-American Arts', 'Charlotte', 18404, 'receiving'),
('deltaartscenter', 'Delta Arts Center', 'Winston-Salem', 18405, 'receiving'),
('diggsgallerywinstonsalemstateuniversity', 'Diggs Gallery - Winston-Salem State University', 'Winston-Salem', 18406, 'receiving'),
('northcarolinacentraluniversityartmuseum', 'NC Central University Art Museum', 'Durham', 18407, 'receiving'),
('northcarolinaatstateuniversitygalleries', 'NC A&T State University Galleries', 'Greensboro', 18408, 'receiving'),
('cameronartmuseum', 'Cameron Art Museum', 'Wilmington', 18409, 'receiving'),
('maimyettablackfineartsmuseum', 'Mattye Reed African Heritage Center', 'Greensboro', 18410, 'receiving'),
('csbrownculturalartscenter', 'CS Brown Cultural Arts Center', 'Winton', 18411, 'receiving'),
('tryonpalacecollections', 'Tryon Palace Collections', 'New Bern', 18412, 'receiving'),
('northcarolinamuseumofhistory', 'North Carolina Museum of History', 'Raleigh', 18413, 'receiving'),
('maritimemuseumsbeaufort', 'NC Maritime Museum - Beaufort', 'Beaufort', 18414, 'receiving'),
('roanokeislandfestivalpark', 'Roanoke Island Festival Park', 'Manteo', 18415, 'receiving'),
('82ndairbornedivisionwarmemorialmuseum', '82nd Airborne Division War Memorial Museum', 'Fort Liberty', 18416, 'receiving'),
('africanamericanculturalcomplex', 'African American Cultural Complex', 'Raleigh', 18417, 'receiving'),
('americanclassicmotorcyclemuseum', 'American Classic Motorcycle Museum', 'Asheboro', 18418, 'receiving'),
('andygriffithmuseum', 'Andy Griffith Museum', 'Mount Airy', 18419, 'receiving');

-- ============================================================
-- SCIENCE DATABASE (extends existing BrarnerScience)
-- ============================================================
CREATE DATABASE IF NOT EXISTS BrarnerScience;
USE BrarnerScience;

CREATE TABLE IF NOT EXISTS science_entries (
    id INT AUTO_INCREMENT PRIMARY KEY,
    category VARCHAR(100) NOT NULL,
    title VARCHAR(255) NOT NULL,
    description TEXT,
    classification VARCHAR(100),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS experiments (
    id INT AUTO_INCREMENT PRIMARY KEY,
    experiment_name VARCHAR(255) NOT NULL,
    experiment_data TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Seed science categories from fines
INSERT IGNORE INTO science_entries (category, title, description, classification) VALUES
('frontermus', 'Fronterminusetic Standard', 'Catching the close regards of others as Held; Same. So as to impose a low-scoring Standard as High and Sane.', 'fines'),
('protethic', 'Protethic Technique', 'Catching science scores to show underhanded or completely clean underhanded technique to show the masses of a Can of care M.', 'fines');
