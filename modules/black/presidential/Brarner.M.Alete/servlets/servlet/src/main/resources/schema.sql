-- Brarner.M.Alete Database Schema
-- MySQL/MariaDB

CREATE DATABASE IF NOT EXISTS BrarnerDB;
USE BrarnerDB;

-- User management
CREATE TABLE IF NOT EXISTS users (
    id INT AUTO_INCREMENT PRIMARY KEY,
    username VARCHAR(64) NOT NULL UNIQUE,
    password_hash VARCHAR(64) NOT NULL,
    role ENUM('admin','viewer') NOT NULL DEFAULT 'viewer',
    active TINYINT(1) NOT NULL DEFAULT 1,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- POST documents queue
CREATE TABLE IF NOT EXISTS documents (
    id INT AUTO_INCREMENT PRIMARY KEY,
    source VARCHAR(128),
    doc_type VARCHAR(64),
    content LONGTEXT,
    submitted_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    retrieved_by INT NULL,
    retrieved_at TIMESTAMP NULL,
    FOREIGN KEY (retrieved_by) REFERENCES users(id)
);

-- Institutional contracts
CREATE TABLE IF NOT EXISTS contracts (
    id INT AUTO_INCREMENT PRIMARY KEY,
    institution VARCHAR(128) NOT NULL,
    description TEXT,
    terms TEXT,
    status ENUM('draft','active','completed','cancelled') DEFAULT 'draft',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NULL ON UPDATE CURRENT_TIMESTAMP
);

-- Student finals submissions
CREATE TABLE IF NOT EXISTS student_finals (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    course VARCHAR(128) NOT NULL,
    final_data LONGTEXT,
    grade VARCHAR(4) NULL,
    submitted_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    graded_at TIMESTAMP NULL,
    FOREIGN KEY (user_id) REFERENCES users(id)
);

-- Signal processing experiments (used by source-code instances)
CREATE TABLE IF NOT EXISTS experiments (
    id INT AUTO_INCREMENT PRIMARY KEY,
    experiment_name VARCHAR(128),
    experiment_data LONGTEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Default admin account (password: admin — change immediately)
INSERT IGNORE INTO users (username, password_hash, role)
VALUES ('admin', SHA2('admin', 256), 'admin');
