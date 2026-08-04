#!/bin/bash
# ═══════════════════════════════════════════════════════════════════════════════════
# NitroWebExpress™ — Messaging System Database Setup
# Creates nwe_messaging tables for cross-module posting feature.
# Supports anonymous & profiled users, subgroups, admin CRUD.
# SAFE: Uses CREATE IF NOT EXISTS.
# ═══════════════════════════════════════════════════════════════════════════════════
set -e

echo "[*] Creating nwe_messaging database..."

mysql -u root -e "
CREATE DATABASE IF NOT EXISTS nwe_messaging;
USE nwe_messaging;

-- ───────────────────────────────────────────────────────────────────────
-- Users: profiled users (anonymous users post without registration)
-- ───────────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS msg_users (
    id INT AUTO_INCREMENT PRIMARY KEY,
    username VARCHAR(64) NOT NULL UNIQUE,
    display_name VARCHAR(128),
    password_hash VARCHAR(128) NOT NULL,
    salt VARCHAR(64) NOT NULL,
    email VARCHAR(256),
    avatar_color VARCHAR(7) DEFAULT '#3b82f6',
    is_admin BOOLEAN DEFAULT FALSE,
    is_banned BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    last_active TIMESTAMP NULL,
    INDEX idx_username (username)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ───────────────────────────────────────────────────────────────────────
-- Subgroups: user-created topic groups
-- ───────────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS msg_subgroups (
    id INT AUTO_INCREMENT PRIMARY KEY,
    group_name VARCHAR(128) NOT NULL,
    group_slug VARCHAR(128) NOT NULL UNIQUE,
    description VARCHAR(512),
    owner_id INT NOT NULL,
    module_name VARCHAR(64) NOT NULL,
    is_public BOOLEAN DEFAULT TRUE,
    is_archived BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_module (module_name),
    INDEX idx_owner (owner_id),
    INDEX idx_slug (group_slug)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ───────────────────────────────────────────────────────────────────────
-- Subgroup Members: who can post in a subgroup
-- ───────────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS msg_subgroup_members (
    id INT AUTO_INCREMENT PRIMARY KEY,
    subgroup_id INT NOT NULL,
    user_id INT NOT NULL,
    role ENUM('member', 'moderator', 'owner') DEFAULT 'member',
    joined_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE KEY uk_group_user (subgroup_id, user_id),
    INDEX idx_group (subgroup_id),
    INDEX idx_user (user_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ───────────────────────────────────────────────────────────────────────
-- Posts: messages from both anonymous and profiled users
-- ───────────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS msg_posts (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    module_name VARCHAR(64) NOT NULL,
    subgroup_id INT DEFAULT NULL,
    user_id INT DEFAULT NULL,
    anonymous_name VARCHAR(64) DEFAULT 'Anonymous',
    title VARCHAR(255),
    content TEXT NOT NULL,
    post_type ENUM('message', 'concern', 'idea', 'reply') DEFAULT 'message',
    parent_id BIGINT DEFAULT NULL,
    ip_address VARCHAR(45),
    is_pinned BOOLEAN DEFAULT FALSE,
    is_deleted BOOLEAN DEFAULT FALSE,
    edit_count INT DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NULL ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_module (module_name),
    INDEX idx_subgroup (subgroup_id),
    INDEX idx_user (user_id),
    INDEX idx_parent (parent_id),
    INDEX idx_created (created_at),
    INDEX idx_type (post_type)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ───────────────────────────────────────────────────────────────────────
-- Default admin user (password: NWE_MSG_ADMIN_2026)
-- Salt + SHA-256 hash inline for portability
-- ───────────────────────────────────────────────────────────────────────
INSERT IGNORE INTO msg_users (username, display_name, password_hash, salt, email, is_admin) VALUES
    ('admin', 'Administrator', 'b8b78bb78a54ed2b3fae1dbd6a0c29e3e3c3f6a7d4f5c6e7a8b9c0d1e2f3a4b5', 'NWE2026SALT', 'mearvk@mearvk.us', TRUE);
"

echo "[OK] nwe_messaging database ready."
echo "     Tables: msg_users, msg_subgroups, msg_subgroup_members, msg_posts"
echo "     Default admin: admin / NWE_MSG_ADMIN_2026"
