-- Brarner.M.Alete™ — BrarnerScience Table Definitions
-- Shared SQL used by all OS install scripts

CREATE TABLE IF NOT EXISTS animalia (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    kingdom VARCHAR(100),
    phylum VARCHAR(100),
    subphylum VARCHAR(100),
    class_name VARCHAR(100),
    subclass VARCHAR(100),
    order_name VARCHAR(100),
    suborder VARCHAR(100),
    infraorder VARCHAR(100),
    family_name VARCHAR(100),
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_kingdom (kingdom),
    INDEX idx_class (class_name),
    INDEX idx_order (order_name),
    INDEX idx_family (family_name)
);

CREATE TABLE IF NOT EXISTS species (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    kingdom VARCHAR(100),
    phylum VARCHAR(100),
    class_name VARCHAR(100),
    order_name VARCHAR(100),
    family_name VARCHAR(100),
    species_name VARCHAR(255),
    common_name VARCHAR(255),
    description TEXT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_family (family_name),
    INDEX idx_species (species_name)
);

CREATE TABLE IF NOT EXISTS postal (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    zip_code VARCHAR(10),
    city VARCHAR(100),
    state VARCHAR(50),
    county VARCHAR(100),
    latitude DECIMAL(10,6),
    longitude DECIMAL(10,6),
    INDEX idx_state (state),
    INDEX idx_zip (zip_code)
);

CREATE TABLE IF NOT EXISTS art_works (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    museum_name VARCHAR(255),
    title VARCHAR(500),
    artist VARCHAR(255),
    year_created VARCHAR(20),
    medium VARCHAR(255),
    collection VARCHAR(255),
    INDEX idx_museum (museum_name),
    INDEX idx_artist (artist)
);

CREATE TABLE IF NOT EXISTS publications (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    source_name VARCHAR(255),
    title VARCHAR(500),
    authors TEXT,
    doi VARCHAR(255),
    year_published VARCHAR(10),
    abstract_text TEXT,
    INDEX idx_source (source_name),
    INDEX idx_doi (doi)
);
