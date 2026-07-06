-- Science Database Creation Script
-- MEARVK LLC

CREATE DATABASE IF NOT EXISTS Science;
USE Science;

-- Main experiments table
CREATE TABLE IF NOT EXISTS experiments (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    `date` DATETIME DEFAULT CURRENT_TIMESTAMP,
    experiment_name VARCHAR(255),
    educator VARCHAR(255),
    science_officer VARCHAR(255),
    grade VARCHAR(50),
    `rank` VARCHAR(100),
    experiment_data TEXT,
    occullor_class VARCHAR(100),
    resident_rank VARCHAR(100),
    master_id_rank VARCHAR(100),
    aschooler_rank VARCHAR(100),
    final_positron_spectrum TEXT,
    final_education_rank VARCHAR(100),
    loose_coils TEXT,
    god_her_id_rank VARCHAR(100),
    final_coils TEXT
);

-- Persons source table
CREATE TABLE IF NOT EXISTS persons (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    first_name VARCHAR(255),
    last_name VARCHAR(255),
    title VARCHAR(100),
    `rank` VARCHAR(100),
    affiliation VARCHAR(255),
    contact_info VARCHAR(255),
    notes TEXT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- Teachers source table
CREATE TABLE IF NOT EXISTS teachers (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    person_id BIGINT,
    subject VARCHAR(255),
    grade_level VARCHAR(50),
    institution VARCHAR(255),
    `rank` VARCHAR(100),
    certification VARCHAR(255),
    years_experience INT,
    notes TEXT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (person_id) REFERENCES persons(id)
);

-- Educators source table
CREATE TABLE IF NOT EXISTS educators (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    person_id BIGINT,
    discipline VARCHAR(255),
    education_rank VARCHAR(100),
    institution VARCHAR(255),
    department VARCHAR(255),
    `rank` VARCHAR(100),
    publications TEXT,
    notes TEXT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (person_id) REFERENCES persons(id)
);

-- Scientists source table
CREATE TABLE IF NOT EXISTS scientists (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    person_id BIGINT,
    field VARCHAR(255),
    specialization VARCHAR(255),
    `rank` VARCHAR(100),
    lab VARCHAR(255),
    clearance_level VARCHAR(100),
    publications TEXT,
    experiment_count INT DEFAULT 0,
    notes TEXT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (person_id) REFERENCES persons(id)
);

-- Universities source table
CREATE TABLE IF NOT EXISTS universities (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(255),
    country VARCHAR(100),
    city VARCHAR(100),
    `rank` VARCHAR(100),
    department VARCHAR(255),
    accreditation VARCHAR(255),
    founded_year INT,
    notes TEXT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- God source table
CREATE TABLE IF NOT EXISTS god (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    designation VARCHAR(255),
    `rank` VARCHAR(100),
    domain VARCHAR(255),
    authority_level VARCHAR(100),
    source_reference TEXT,
    notes TEXT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- Linking table: experiment sources
CREATE TABLE IF NOT EXISTS experiment_sources (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    experiment_id BIGINT,
    source_type ENUM('person','teacher','educator','scientist','university','god'),
    source_id BIGINT,
    role VARCHAR(255),
    notes TEXT,
    FOREIGN KEY (experiment_id) REFERENCES experiments(id)
);
