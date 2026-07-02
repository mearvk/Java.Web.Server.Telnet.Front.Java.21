-- Brarner.M.Alete Animalia Science Database
-- Install Script: checks for existing science database ownership before creating

-- Check if Science DB exists and belongs to us (MEARVK brand)
-- If not found or not ours, create BrarnerScience as our own

DELIMITER //

DROP PROCEDURE IF EXISTS brarner_install_animalia//

CREATE PROCEDURE brarner_install_animalia()
BEGIN
    DECLARE db_exists INT DEFAULT 0;
    DECLARE is_ours INT DEFAULT 0;

    -- Check if Science database exists
    SELECT COUNT(*) INTO db_exists FROM information_schema.SCHEMATA WHERE SCHEMA_NAME = 'Science';

    IF db_exists > 0 THEN
        -- Check if it carries our brand (installer_registry table with our tax id)
        SELECT COUNT(*) INTO is_ours
        FROM information_schema.TABLES
        WHERE TABLE_SCHEMA = 'Science' AND TABLE_NAME = 'installer_registry';

        IF is_ours > 0 THEN
            -- Verify it's actually ours
            SET @sql = 'SELECT COUNT(*) INTO @brand_check FROM Science.installer_registry WHERE brand IN (''MEARVK'', ''Brarner.M.Alete'', ''Max Rupplin'')';
            PREPARE stmt FROM @sql;
            EXECUTE stmt;
            DEALLOCATE PREPARE stmt;
            SET is_ours = @brand_check;
        END IF;
    END IF;

    IF db_exists > 0 AND is_ours > 0 THEN
        -- Use existing Science database — it's ours
        SELECT 'Using existing Science database (MEARVK brand verified)' AS status;
    ELSE
        -- Create our own science database — existing one is not ours or doesn't exist
        CREATE DATABASE IF NOT EXISTS BrarnerScience;
        SELECT 'Created BrarnerScience database (independent instance)' AS status;
    END IF;
END//

DELIMITER ;

CALL brarner_install_animalia();

-- Determine which DB to use
SET @target_db = IF(
    (SELECT COUNT(*) FROM information_schema.TABLES
     WHERE TABLE_SCHEMA = 'Science' AND TABLE_NAME = 'installer_registry'
     AND EXISTS (SELECT 1 FROM Science.installer_registry WHERE brand IN ('MEARVK','Brarner.M.Alete','Max Rupplin'))) > 0,
    'Science', 'BrarnerScience'
);

-- Install into BrarnerScience (safe default — always create here)
CREATE DATABASE IF NOT EXISTS BrarnerScience;
USE BrarnerScience;

-- Installer registry: proves ownership/brand for this database
CREATE TABLE IF NOT EXISTS installer_registry (
    id INT AUTO_INCREMENT PRIMARY KEY,
    brand VARCHAR(128) NOT NULL,
    tax_id VARCHAR(64) NOT NULL,
    installer_name VARCHAR(128) NOT NULL,
    installed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    version VARCHAR(32) DEFAULT '1.0'
);

-- Insert our brand marker
INSERT INTO installer_registry (brand, tax_id, installer_name) VALUES
    ('MEARVK', 'MEARVK-LLC-2026', 'Maximilian Eric Alexander Rupplin von Keffikon'),
    ('Brarner.M.Alete', 'MEARVK-LLC-2026', 'Brarner.M.Alete Signal Processing Platform'),
    ('Max Rupplin', 'MEARVK-LLC-2026', 'Max Rupplin')
ON DUPLICATE KEY UPDATE installed_at = CURRENT_TIMESTAMP;

-- Animalia taxonomy table
CREATE TABLE IF NOT EXISTS animalia (
    id INT AUTO_INCREMENT PRIMARY KEY,
    kingdom VARCHAR(64) DEFAULT 'Animalia',
    phylum VARCHAR(128),
    subphylum VARCHAR(128),
    class_name VARCHAR(128),
    subclass VARCHAR(128),
    superorder VARCHAR(128),
    order_name VARCHAR(128),
    suborder VARCHAR(128),
    infraorder VARCHAR(128),
    family_name VARCHAR(128) NOT NULL,
    instance_port INT,
    active TINYINT(1) DEFAULT 0,
    installer_tax_id VARCHAR(64) DEFAULT 'MEARVK-LLC-2026',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_phylum (phylum),
    INDEX idx_class (class_name),
    INDEX idx_family (family_name)
);

-- Species signal processing experiments
CREATE TABLE IF NOT EXISTS species_experiments (
    id INT AUTO_INCREMENT PRIMARY KEY,
    phylum VARCHAR(128) NOT NULL,
    class_name VARCHAR(128),
    family_name VARCHAR(128),
    experiment_name VARCHAR(256),
    experiment_data LONGTEXT,
    installer_tax_id VARCHAR(64) DEFAULT 'MEARVK-LLC-2026',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_phylum_exp (phylum)
);

-- Species instances status
CREATE TABLE IF NOT EXISTS species_instances (
    id INT AUTO_INCREMENT PRIMARY KEY,
    phylum VARCHAR(128) NOT NULL,
    port INT NOT NULL,
    status ENUM('active','standby','offline') DEFAULT 'standby',
    last_data_received TIMESTAMP NULL,
    installer_tax_id VARCHAR(64) DEFAULT 'MEARVK-LLC-2026',
    UNIQUE KEY uk_phylum (phylum)
);
