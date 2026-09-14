#!/bin/bash
# Emeter™ — Setup MySQL database
set -e
# SAFE: Uses CREATE IF NOT EXISTS. Never drops or overwrites existing data.
# Can be run repeatedly after git pull without risk to production databases.
echo "[*] NitroWebExpress™ — Creating nwe_emeter database..."

mysql -u root -e "
CREATE DATABASE IF NOT EXISTS nwe_emeter;
USE nwe_emeter;

CREATE TABLE IF NOT EXISTS instructions (
    id INT AUTO_INCREMENT PRIMARY KEY,
    topic VARCHAR(128) NOT NULL,
    level VARCHAR(64),
    content TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_topic (topic),
    INDEX idx_level (level)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS readings (
    id INT AUTO_INCREMENT PRIMARY KEY,
    session_id VARCHAR(64) NOT NULL,
    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    ta_value FLOAT,
    tone_level VARCHAR(64),
    notes TEXT,
    INDEX idx_session_id (session_id),
    INDEX idx_timestamp (timestamp)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS calibration (
    id INT AUTO_INCREMENT PRIMARY KEY,
    level_name VARCHAR(64) NOT NULL,
    description TEXT,
    procedure_steps TEXT,
    INDEX idx_level_name (level_name)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Seed instructions
INSERT IGNORE INTO instructions (id, topic, level, content) VALUES
(1, 'Introduction', 'Beginner', 'The E-Meter is a precision instrument that measures changes in electrical resistance. It is used as a pastoral counseling aid.'),
(2, 'Theory of Operation', 'Intermediate', 'The meter passes a small electrical current through the body via two electrodes held in the hands. Changes in resistance correspond to mental and emotional states.'),
(3, 'Calibration Procedure', 'All', 'Before each session: set tone arm to 2.0, adjust sensitivity to produce a 1/3 dial drop on a known squeeze, verify needle is at Set.'),
(4, 'Reading Interpretation', 'Advanced', 'A falling needle indicates discharge. A rising needle indicates charge building. A floating needle indicates release of attention from a subject.'),
(5, 'Session Protocols', 'Professional', 'Begin with can squeeze test. Verify TA range 2.0-3.5. Note all reads: fall, rise, theta bop, rock slam, floating needle.'),
(6, 'Advanced Techniques', 'Expert', 'Rock slam reads indicate evil intention areas. Theta bop indicates exterior state. Stage four needle indicates clear.');

-- Seed calibration
INSERT IGNORE INTO calibration (id, level_name, description, procedure_steps) VALUES
(1, 'Set', 'Needle at rest position on dial face', '1. Turn on meter 2. Have subject hold cans 3. Adjust trim knob until needle rests at Set mark'),
(2, 'Sensitivity', 'Response amplitude calibration', '1. Set sensitivity to 16 initially 2. Have subject squeeze cans firmly 3. Adjust until squeeze produces 1/3 to 1/2 dial drop'),
(3, 'Range', 'Tone Arm operational range', '1. TA should read between 2.0 and 3.5 2. Below 2.0 indicates overrun 3. Above 3.5 indicates heavy charge'),
(4, 'Tone Arm', 'Counter-force positioning', '1. TA knob controls counter-weight 2. Adjust to keep needle at Set 3. Read TA position from dial (2.0 nominal)');
"

echo "[OK] NitroWebExpress™ — nwe_emeter database ready."
