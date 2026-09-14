#!/bin/bash
# ═══════════════════════════════════════════════════════════════════════════════════
# NitroWebExpress™ — TandemEquals Database Setup
# Creates nwe_tandem_equals database.
#
# Four Layers of the Human Intellect Modulator Simplex & Control Curve:
#   Layer 1: Perception (intake, sensory, raw data)
#   Layer 2: Cognition (processing, pattern, logic)
#   Layer 3: Modulation (calibration, adjustment, balance)
#   Layer 4: Expression (output, control curve, actuation)
#
# SAFE: Uses CREATE IF NOT EXISTS.
# Installer Tech ID: Max Rupplin
# ═══════════════════════════════════════════════════════════════════════════════════
set -e

echo "[*] Creating nwe_tandem_equals database..."

mysql -u root -e "
CREATE DATABASE IF NOT EXISTS nwe_tandem_equals;
USE nwe_tandem_equals;

-- ───────────────────────────────────────────────────────────────────────
-- Layer 1: PERCEPTION — intake signals, raw sensory inputs
-- ───────────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS perception (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    signal_name VARCHAR(128) NOT NULL,
    signal_type ENUM('sensory', 'data', 'emotional', 'environmental', 'temporal') NOT NULL,
    amplitude DOUBLE NOT NULL DEFAULT 0.0,
    frequency DOUBLE DEFAULT 1.0,
    phase DOUBLE DEFAULT 0.0,
    origin VARCHAR(256),
    clarity DOUBLE DEFAULT 1.0,
    noise_floor DOUBLE DEFAULT 0.0,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_type (signal_type),
    INDEX idx_name (signal_name),
    INDEX idx_active (is_active)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ───────────────────────────────────────────────────────────────────────
-- Layer 2: COGNITION — pattern recognition, logic gates, reasoning
-- ───────────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS cognition (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    pattern_name VARCHAR(128) NOT NULL,
    pattern_type ENUM('recognition', 'logic', 'analogy', 'inference', 'memory') NOT NULL,
    perception_ids TEXT,
    weight DOUBLE DEFAULT 1.0,
    confidence DOUBLE DEFAULT 0.0,
    complexity INT DEFAULT 1,
    gate_type ENUM('AND', 'OR', 'XOR', 'NOT', 'NAND', 'PASS', 'THRESHOLD') DEFAULT 'PASS',
    threshold DOUBLE DEFAULT 0.5,
    output_value DOUBLE DEFAULT 0.0,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_type (pattern_type),
    INDEX idx_gate (gate_type),
    INDEX idx_confidence (confidence)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ───────────────────────────────────────────────────────────────────────
-- Layer 3: MODULATION — calibration, balance, gain control
-- ───────────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS modulation (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    modulator_name VARCHAR(128) NOT NULL,
    modulator_type ENUM('gain', 'attenuation', 'bias', 'filter', 'envelope', 'limiter') NOT NULL,
    cognition_ids TEXT,
    gain DOUBLE DEFAULT 1.0,
    bias DOUBLE DEFAULT 0.0,
    attack_ms DOUBLE DEFAULT 10.0,
    decay_ms DOUBLE DEFAULT 100.0,
    sustain_level DOUBLE DEFAULT 0.7,
    release_ms DOUBLE DEFAULT 200.0,
    curve_type ENUM('linear', 'exponential', 'logarithmic', 'sigmoid', 'step') DEFAULT 'linear',
    simplex_order INT DEFAULT 1,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_type (modulator_type),
    INDEX idx_curve (curve_type),
    INDEX idx_simplex (simplex_order)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ───────────────────────────────────────────────────────────────────────
-- Layer 4: EXPRESSION — output, control curve, actuation
-- ───────────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS expression (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    expression_name VARCHAR(128) NOT NULL,
    expression_type ENUM('speech', 'action', 'decision', 'inhibition', 'creation', 'signal') NOT NULL,
    modulation_ids TEXT,
    control_value DOUBLE DEFAULT 0.0,
    curve_position DOUBLE DEFAULT 0.0,
    velocity DOUBLE DEFAULT 0.0,
    direction ENUM('forward', 'reverse', 'lateral', 'hold', 'release') DEFAULT 'forward',
    intensity DOUBLE DEFAULT 0.5,
    precision_grade INT DEFAULT 5,
    is_final BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_type (expression_type),
    INDEX idx_direction (direction),
    INDEX idx_final (is_final)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ───────────────────────────────────────────────────────────────────────
-- CONTROL CURVE — the simplex path from perception to expression
-- ───────────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS control_curve (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    curve_name VARCHAR(128) NOT NULL,
    perception_id BIGINT,
    cognition_id BIGINT,
    modulation_id BIGINT,
    expression_id BIGINT,
    simplex_value DOUBLE DEFAULT 0.0,
    curve_integral DOUBLE DEFAULT 0.0,
    stability DOUBLE DEFAULT 1.0,
    latency_ms DOUBLE DEFAULT 0.0,
    is_complete BOOLEAN DEFAULT FALSE,
    evaluated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_curve (curve_name),
    INDEX idx_complete (is_complete),
    INDEX idx_stability (stability)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ───────────────────────────────────────────────────────────────────────
-- INTELLECT LOG — immutable record of modulator simplex evaluations
-- ───────────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS intellect_log (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    curve_id BIGINT NOT NULL,
    layer_evaluated INT NOT NULL,
    input_vector TEXT,
    output_vector TEXT,
    simplex_delta DOUBLE DEFAULT 0.0,
    note VARCHAR(512),
    evaluator VARCHAR(128) DEFAULT 'system',
    evaluated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_curve (curve_id),
    INDEX idx_layer (layer_evaluated),
    INDEX idx_time (evaluated_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ───────────────────────────────────────────────────────────────────────
-- Seed perception signals
-- ───────────────────────────────────────────────────────────────────────
INSERT IGNORE INTO perception (id, signal_name, signal_type, amplitude, frequency, clarity, origin) VALUES
    (1, 'Visual Acuity', 'sensory', 0.92, 60.0, 0.95, 'optic nerve'),
    (2, 'Auditory Baseline', 'sensory', 0.70, 20000.0, 0.88, 'cochlea'),
    (3, 'Temporal Awareness', 'temporal', 1.0, 1.0, 1.0, 'circadian'),
    (4, 'Emotional Tone', 'emotional', 0.5, 0.1, 0.72, 'limbic'),
    (5, 'Data Stream A', 'data', 0.85, 1000.0, 0.99, 'external input'),
    (6, 'Environmental Pressure', 'environmental', 0.3, 0.01, 0.60, 'barometric');

-- ───────────────────────────────────────────────────────────────────────
-- Seed cognition patterns
-- ───────────────────────────────────────────────────────────────────────
INSERT IGNORE INTO cognition (id, pattern_name, pattern_type, perception_ids, weight, confidence, gate_type, threshold) VALUES
    (1, 'Focus Gate', 'recognition', '1,2,3', 1.2, 0.88, 'THRESHOLD', 0.6),
    (2, 'Logic Chain Alpha', 'logic', '5', 1.0, 0.95, 'AND', 0.5),
    (3, 'Emotional Inference', 'inference', '4,6', 0.8, 0.65, 'OR', 0.4),
    (4, 'Pattern Memory', 'memory', '1,2,5', 1.5, 0.90, 'PASS', 0.0),
    (5, 'Analogy Bridge', 'analogy', '3,4,5', 0.9, 0.72, 'XOR', 0.5);

-- ───────────────────────────────────────────────────────────────────────
-- Seed modulation controls
-- ───────────────────────────────────────────────────────────────────────
INSERT IGNORE INTO modulation (id, modulator_name, modulator_type, cognition_ids, gain, bias, curve_type, simplex_order) VALUES
    (1, 'Attention Gain', 'gain', '1,4', 1.5, 0.0, 'logarithmic', 1),
    (2, 'Emotional Filter', 'filter', '3', 0.8, -0.1, 'sigmoid', 2),
    (3, 'Logic Amplifier', 'gain', '2', 2.0, 0.0, 'linear', 1),
    (4, 'Calm Limiter', 'limiter', '3,5', 0.6, 0.2, 'exponential', 3),
    (5, 'Precision Envelope', 'envelope', '1,2,4', 1.0, 0.0, 'sigmoid', 2);

-- ───────────────────────────────────────────────────────────────────────
-- Seed expression outputs
-- ───────────────────────────────────────────────────────────────────────
INSERT IGNORE INTO expression (id, expression_name, expression_type, modulation_ids, control_value, direction, intensity) VALUES
    (1, 'Verbal Response', 'speech', '1,3', 0.85, 'forward', 0.7),
    (2, 'Decision Execute', 'decision', '1,2,3', 0.92, 'forward', 0.9),
    (3, 'Creative Output', 'creation', '5', 0.60, 'lateral', 0.6),
    (4, 'Inhibition Hold', 'inhibition', '4', 0.30, 'hold', 0.3),
    (5, 'Signal Relay', 'signal', '1,5', 0.75, 'forward', 0.8);

-- ───────────────────────────────────────────────────────────────────────
-- Seed control curves (complete simplex paths)
-- ───────────────────────────────────────────────────────────────────────
INSERT IGNORE INTO control_curve (id, curve_name, perception_id, cognition_id, modulation_id, expression_id, simplex_value, stability, is_complete) VALUES
    (1, 'Focus→Decision', 1, 1, 1, 2, 0.88, 0.95, TRUE),
    (2, 'Data→Logic→Output', 5, 2, 3, 1, 0.91, 0.98, TRUE),
    (3, 'Emotion→Filter→Hold', 4, 3, 2, 4, 0.45, 0.72, TRUE),
    (4, 'Pattern→Envelope→Create', 1, 4, 5, 3, 0.70, 0.85, TRUE),
    (5, 'Temporal→Analogy→Signal', 3, 5, 4, 5, 0.62, 0.80, TRUE);

-- ═══════════════════════════════════════════════════════════════════════
-- SAIMPTOM RESOLUTION TABLES (from kernel module design)
-- TandemEquals kernel: 42x42 choice matrix, stereo mind recovery
-- ═══════════════════════════════════════════════════════════════════════

-- ───────────────────────────────────────────────────────────────────────
-- Saimptom Sessions: each resolution attempt
-- ───────────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS saimptom_sessions (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    domain VARCHAR(64) NOT NULL,
    user_hash VARCHAR(64),
    ip_address VARCHAR(45),
    state ENUM('idle', 'loaded', 'answering', 'resolving', 'resolved') DEFAULT 'idle',
    answers_given INT DEFAULT 0,
    overconfidence INT DEFAULT 0,
    stereo_recovered BOOLEAN DEFAULT FALSE,
    choice_magnitude INT DEFAULT 0,
    noise_magnitude INT DEFAULT 0,
    dominant_row INT DEFAULT 0,
    dominant_col INT DEFAULT 0,
    choice_summary VARCHAR(512),
    noise_summary VARCHAR(512),
    province_wisdom TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    resolved_at TIMESTAMP NULL,
    INDEX idx_domain (domain),
    INDEX idx_state (state),
    INDEX idx_stereo (stereo_recovered),
    INDEX idx_created (created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ───────────────────────────────────────────────────────────────────────
-- Saimptom Answers: individual answers per session (-1000 to +1000)
-- ───────────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS saimptom_answers (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    session_id BIGINT NOT NULL,
    answer_index INT NOT NULL,
    answer_value INT NOT NULL,
    confidence_at_step INT DEFAULT 0,
    answered_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_session (session_id),
    FOREIGN KEY (session_id) REFERENCES saimptom_sessions(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ───────────────────────────────────────────────────────────────────────
-- Choice Domains: the 16 predefined areas of dilemma
-- ───────────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS choice_domains (
    id INT AUTO_INCREMENT PRIMARY KEY,
    domain_name VARCHAR(64) NOT NULL UNIQUE,
    description VARCHAR(512),
    matrix_bias VARCHAR(128),
    times_selected INT DEFAULT 0,
    avg_overconfidence DOUBLE DEFAULT 0.0,
    stereo_recovery_rate DOUBLE DEFAULT 0.0
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

INSERT IGNORE INTO choice_domains (domain_name, description, matrix_bias) VALUES
    ('career', 'Professional direction, job changes, role decisions', 'relational quadrant +150'),
    ('relationship', 'Interpersonal bonds, commitments, separations', 'relational quadrant +150'),
    ('financial', 'Money decisions, investments, spending philosophy', 'relational quadrant +150'),
    ('health', 'Physical/mental health choices, lifestyle changes', 'relational quadrant +150'),
    ('creative', 'Artistic direction, project choices, creative risks', 'systemic quadrant +150'),
    ('technical', 'Engineering decisions, architecture, tooling', 'systemic quadrant +150'),
    ('ethical', 'Moral dilemmas, values conflicts, principle vs pragmatism', 'systemic quadrant +150'),
    ('geographic', 'Location decisions, moves, travel, roots', 'systemic quadrant +150'),
    ('temporal', 'Timing decisions, now vs later, patience vs urgency', 'internal quadrant +150'),
    ('priority', 'What matters more, ordering of concerns', 'internal quadrant +150'),
    ('risk', 'Safety vs opportunity, conservative vs bold', 'internal quadrant +150'),
    ('commitment', 'Depth vs breadth, loyalty, persistence vs pivot', 'internal quadrant +150'),
    ('freedom', 'Independence vs belonging, structure vs openness', 'internal quadrant +150'),
    ('legacy', 'What to leave behind, long-term impact, meaning', 'internal quadrant +150'),
    ('community', 'Group participation, civic duty, social investment', 'internal quadrant +150'),
    ('education', 'Learning paths, formal vs informal, depth vs survey', 'internal quadrant +150');
"

echo "[OK] nwe_tandem_equals database ready."
echo "     9 tables: perception, cognition, modulation, expression, control_curve, intellect_log,"
echo "              saimptom_sessions, saimptom_answers, choice_domains"
echo "     16 choice domains seeded. Kernel-aligned saimptom resolution."
