-- ============================================================================
-- Defined Module — MySQL Schema
-- Database: defined_dark_gray
-- Author: Maximilian Eric Alexander Rupplin von Keffikon — MEARVK LLC
-- Engine: InnoDB, utf8mb4
--
-- POLICY: NO DELETE on any table. NO UPDATE on history tables.
-- ============================================================================

CREATE DATABASE IF NOT EXISTS `defined_dark_gray`
  CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

USE `defined_dark_gray`;

-- ----------------------------------------------------------------------------
-- scan_findings: Results from category scans
-- NO DELETE. NO UPDATE.
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `scan_findings` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `category` VARCHAR(64) NOT NULL,
  `finding_text` TEXT NOT NULL,
  `scan_number` INT NOT NULL,
  `scan_date` DATE NOT NULL,
  `created_ts` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  INDEX `idx_scan_findings_category` (`category`),
  INDEX `idx_scan_findings_scan_number` (`scan_number`),
  INDEX `idx_scan_findings_scan_date` (`scan_date`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ----------------------------------------------------------------------------
-- daily_assessments: Daily moral/category assessments
-- NO DELETE. NO UPDATE.
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `daily_assessments` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `assessment_number` INT NOT NULL,
  `assessment_text` TEXT NOT NULL,
  `assessment_date` DATE NOT NULL,
  `created_ts` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  INDEX `idx_daily_assessments_number` (`assessment_number`),
  INDEX `idx_daily_assessments_date` (`assessment_date`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ----------------------------------------------------------------------------
-- moral_weights: Moral disposition weights by region
-- NO DELETE. NO UPDATE on historical rows.
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `moral_weights` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `asia1` FLOAT NOT NULL DEFAULT 0.0,
  `asia2` FLOAT NOT NULL DEFAULT 0.0,
  `united_states` FLOAT NOT NULL DEFAULT 0.0,
  `soviet_russia` FLOAT NOT NULL DEFAULT 0.0,
  `save_date` DATE NOT NULL,
  `created_ts` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  INDEX `idx_moral_weights_save_date` (`save_date`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ----------------------------------------------------------------------------
-- reports: Generated period reports with priority weights
-- NO DELETE. NO UPDATE.
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `reports` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `period` VARCHAR(32) NOT NULL,
  `priority_weights` VARCHAR(128) NOT NULL,
  `report_text` LONGTEXT NOT NULL,
  `report_date` DATE NOT NULL,
  `created_ts` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  INDEX `idx_reports_period` (`period`),
  INDEX `idx_reports_report_date` (`report_date`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ----------------------------------------------------------------------------
-- training_strips: AI training strip data (tiered)
-- NO DELETE. NO UPDATE.
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `training_strips` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `tier` INT NOT NULL,
  `strip_name` VARCHAR(128) NOT NULL,
  `strip_data` JSON NOT NULL,
  `loaded_ts` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  INDEX `idx_training_strips_tier` (`tier`),
  INDEX `idx_training_strips_name` (`strip_name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ----------------------------------------------------------------------------
-- moral_metrics: Metric values per category
-- NO DELETE.
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `moral_metrics` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `metric_name` VARCHAR(128) NOT NULL,
  `metric_value` FLOAT NOT NULL DEFAULT 0.0,
  `category` VARCHAR(64) NOT NULL,
  `updated_ts` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  INDEX `idx_moral_metrics_category` (`category`),
  INDEX `idx_moral_metrics_name` (`metric_name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ----------------------------------------------------------------------------
-- receding_tempers: Temper index and harmonic grease measurements
-- NO DELETE. NO UPDATE.
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `receding_tempers` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `category` VARCHAR(64) NOT NULL,
  `temper_index` FLOAT NOT NULL DEFAULT 0.0,
  `harmonic_grease` FLOAT NOT NULL DEFAULT 0.0,
  `measured_ts` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  INDEX `idx_receding_tempers_category` (`category`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ----------------------------------------------------------------------------
-- internet_inputs: Raw internet scan inputs
-- NO DELETE.
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `internet_inputs` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `source_url` VARCHAR(512) NOT NULL,
  `content_hash` VARCHAR(64) NOT NULL,
  `raw_content` TEXT NOT NULL,
  `processed` BOOLEAN NOT NULL DEFAULT FALSE,
  `scan_number` INT NOT NULL,
  `fetched_ts` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  INDEX `idx_internet_inputs_hash` (`content_hash`),
  INDEX `idx_internet_inputs_processed` (`processed`),
  INDEX `idx_internet_inputs_scan_number` (`scan_number`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ----------------------------------------------------------------------------
-- licentious_connections: Detected suspicious connections
-- NO DELETE. NO UPDATE.
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `licentious_connections` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `source_ip` VARCHAR(45) NOT NULL,
  `target_url` VARCHAR(512) NOT NULL,
  `probability` FLOAT NOT NULL DEFAULT 0.0,
  `category` VARCHAR(64) NOT NULL,
  `detected_ts` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  INDEX `idx_licentious_connections_category` (`category`),
  INDEX `idx_licentious_connections_ip` (`source_ip`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ----------------------------------------------------------------------------
-- signatories: Authorized signatories for command of copy authority
-- NO DELETE.
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `signatories` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `signatory_name` VARCHAR(255) NOT NULL,
  `signatory_role` VARCHAR(128) NOT NULL,
  `authority_level` INT NOT NULL DEFAULT 1,
  `signed_ts` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  INDEX `idx_signatories_name` (`signatory_name`),
  INDEX `idx_signatories_role` (`signatory_role`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ----------------------------------------------------------------------------
-- moral_votes: Moral issue voting records
-- NO DELETE. NO UPDATE.
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `moral_votes` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `voter_name` VARCHAR(255) NOT NULL,
  `vote_value` INT NOT NULL DEFAULT 1,
  `moral_issue` TEXT NOT NULL,
  `voted_ts` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  INDEX `idx_moral_votes_voter` (`voter_name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ----------------------------------------------------------------------------
-- keywords: Active keyword tracking with duration management
-- NO DELETE.
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `keywords` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `keyword` VARCHAR(128) NOT NULL,
  `importance_level` INT NOT NULL DEFAULT 1,
  `duration_days` INT NOT NULL DEFAULT 30,
  `category` VARCHAR(64) NOT NULL,
  `active` BOOLEAN NOT NULL DEFAULT TRUE,
  `created_ts` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  INDEX `idx_keywords_keyword` (`keyword`),
  INDEX `idx_keywords_category` (`category`),
  INDEX `idx_keywords_active` (`active`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ----------------------------------------------------------------------------
-- national_medicine_concerns: Medicine/health concerns by region
-- NO DELETE. NO UPDATE.
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `national_medicine_concerns` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `concern_text` TEXT NOT NULL,
  `region` VARCHAR(64) NOT NULL,
  `severity` INT NOT NULL DEFAULT 1,
  `created_ts` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  INDEX `idx_national_medicine_concerns_region` (`region`),
  INDEX `idx_national_medicine_concerns_severity` (`severity`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================================
-- SEED DATA: Populate 29 categories into moral_metrics with defaults
-- ============================================================================

INSERT INTO `moral_metrics` (`metric_name`, `metric_value`, `category`) VALUES
  ('baseline', 0.0, 'banking'),
  ('baseline', 0.0, 'middle-schools'),
  ('baseline', 0.0, 'strong-middle-schools'),
  ('baseline', 0.0, 'improbable-activity-youth'),
  ('baseline', 0.0, 'firefights-20-plus-casualties'),
  ('baseline', 0.0, 'fire-department-errors-3-plus'),
  ('baseline', 0.0, 'schools-burned-down'),
  ('baseline', 0.0, 'misuse-of-scientology'),
  ('baseline', 0.0, 'known-misuse-public-officials'),
  ('baseline', 0.0, 'unkind-language-books-reading'),
  ('baseline', 0.0, 'unkind-misuse-heads-of-state'),
  ('baseline', 0.0, 'absence-fbi-presence'),
  ('baseline', 0.0, 'absence-border-protection'),
  ('baseline', 0.0, 'unequal-treatment-us-treasury'),
  ('baseline', 0.0, 'unequal-footing-us-state-department'),
  ('baseline', 0.0, 'private-ownership-lsat'),
  ('baseline', 0.0, 'torturers'),
  ('baseline', 0.0, 'rapists'),
  ('baseline', 0.0, 'convicted-murderers'),
  ('baseline', 0.0, 'gods-going-crazy'),
  ('baseline', 0.0, 'anti-god-rhetoric'),
  ('baseline', 0.0, 'against-space-nasa'),
  ('baseline', 0.0, 'anti-political-whisper'),
  ('baseline', 0.0, 'sovietism-vs-socialism'),
  ('baseline', 0.0, 'failing-schools'),
  ('baseline', 0.0, 'failing-final-tests'),
  ('baseline', 0.0, 'non-social-graces'),
  ('baseline', 0.0, 'prayer-against-even-temper'),
  ('baseline', 0.0, 'ntsb');

-- ============================================================================
-- SEED DATA: Primary signatory
-- ============================================================================

INSERT INTO `signatories` (`signatory_name`, `signatory_role`, `authority_level`) VALUES
  ('Max Rupplin', 'Moral Adjuster', 10);
