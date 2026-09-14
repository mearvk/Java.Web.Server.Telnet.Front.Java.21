-- Brarner.M.Alete Art Museums Database
-- Checks for BrarnerScience ownership before installing

-- Only install on our own database (verified by installer_registry)
-- No tax id, no installer on unknown SQL instance

DELIMITER //
DROP PROCEDURE IF EXISTS brarner_install_art//
CREATE PROCEDURE brarner_install_art()
BEGIN
    DECLARE is_ours INT DEFAULT 0;

    SELECT COUNT(*) INTO is_ours FROM information_schema.TABLES
    WHERE TABLE_SCHEMA = 'BrarnerScience' AND TABLE_NAME = 'installer_registry';

    IF is_ours > 0 THEN
        SET @sql = 'SELECT COUNT(*) INTO @brand_ok FROM BrarnerScience.installer_registry WHERE brand IN (''MEARVK'', ''Brarner.M.Alete'', ''Max Rupplin'')';
        PREPARE stmt FROM @sql;
        EXECUTE stmt;
        DEALLOCATE PREPARE stmt;
        SET is_ours = @brand_ok;
    END IF;

    IF is_ours = 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'ABORT: BrarnerScience not found or not owned by MEARVK. No tax id, no installer on unknown SQL instance.';
    END IF;
END//
DELIMITER ;

CALL brarner_install_art();

USE BrarnerScience;

CREATE TABLE IF NOT EXISTS art_museums (
    id INT AUTO_INCREMENT PRIMARY KEY,
    museum_name VARCHAR(256) NOT NULL,
    city VARCHAR(128),
    museum_type VARCHAR(128),
    notes TEXT,
    port INT,
    active TINYINT(1) DEFAULT 1,
    installer_tax_id VARCHAR(64) DEFAULT 'MEARVK-LLC-2026',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_city (city),
    INDEX idx_type (museum_type)
);

CREATE TABLE IF NOT EXISTS art_experiments (
    id INT AUTO_INCREMENT PRIMARY KEY,
    museum_name VARCHAR(256),
    city VARCHAR(128),
    experiment_name VARCHAR(256),
    experiment_data LONGTEXT,
    installer_tax_id VARCHAR(64) DEFAULT 'MEARVK-LLC-2026',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_museum (museum_name)
);
INSERT IGNORE INTO art_museums (museum_name, city, museum_type, notes, installer_tax_id) VALUES
('North Carolina Museum of Art','Raleigh','State Art Museum','Major statewide art museum; extensive permanent collection','MEARVK-LLC-2026'),
('Ackland Art Museum','Chapel Hill','University Museum','UNC-Chapel Hill; Asian, European, African, contemporary art','MEARVK-LLC-2026'),
('A.D. Gallery','Pembroke','University Gallery','UNC Pembroke; contemporary and student exhibitions','MEARVK-LLC-2026'),
('African American Atelier','Greensboro','Art Center','African American visual arts; Greensboro Cultural Center','MEARVK-LLC-2026'),
('Harvey B. Gantt Center for African American Arts + Culture','Charlotte','Art Museum','African American art, culture, and history','MEARVK-LLC-2026'),
('Delta Arts Center','Winston-Salem','Art Center','African American arts and culture','MEARVK-LLC-2026'),
('Diggs Gallery (Winston-Salem State University)','Winston-Salem','University Museum','African and African Diaspora art; major university collection','MEARVK-LLC-2026'),
('North Carolina Central University Art Museum','Durham','University Museum','African American art; NCCU campus','MEARVK-LLC-2026'),
('North Carolina A&T State University Galleries','Greensboro','University Galleries','University art collections; rotating exhibitions','MEARVK-LLC-2026'),
('Cameron Art Museum','Wilmington','Art Museum','Regional and national art; historic collections','MEARVK-LLC-2026'),
('Maimy Etta Black Fine Arts Museum','Forest City','Art Museum','Local fine arts museum','MEARVK-LLC-2026'),
('C.S. Brown Cultural Arts Center','Winton','Art Center','Cultural arts and heritage center','MEARVK-LLC-2026'),
('Tryon Palace Collections','New Bern','Historic Site Museum','State historic site with art and decorative arts collections','MEARVK-LLC-2026'),
('North Carolina Museum of History','Raleigh','State Museum','Statewide historical collections including art & artifacts','MEARVK-LLC-2026'),
('Maritime Museums (Beaufort','Hatteras','Southport)','Multiple','MEARVK-LLC-2026'),
('Roanoke Island Festival Park','Manteo','State Historic Park','Historic and cultural collections','MEARVK-LLC-2026'),
('82nd Airborne Division War Memorial Museum','Fort Liberty','Military Museum','Includes historical art and artifacts','MEARVK-LLC-2026'),
('African American Cultural Complex','Raleigh','Art & History Center','African American contributions; art collections','MEARVK-LLC-2026'),
('American Classic Motorcycle Museum','Asheboro','Specialty Museum','Includes design and mechanical art','MEARVK-LLC-2026'),
('Andy Griffith Museum','Mount Airy','Heritage Museum','Cultural artifacts including visual materials','MEARVK-LLC-2026');
