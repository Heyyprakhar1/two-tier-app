-- MySQL Database Schema for Todo Application
-- This script is auto-loaded when the MySQL container initialises

-- Create database (already exists, but just in case)
CREATE DATABASE IF NOT EXISTS mydb;

-- Use the database
USE mydb;

-- Create todos table (IF NOT EXISTS prevents errors on reload)
CREATE TABLE IF NOT EXISTS todos (
    id INT AUTO_INCREMENT PRIMARY KEY,
    task VARCHAR(255) NOT NULL,
    status ENUM('pending', 'completed') DEFAULT 'pending',
    deleted BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP NULL,
    INDEX idx_status (status),
    INDEX idx_created_at (created_at),
    INDEX idx_deleted (deleted)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Insert sample data (only if the table is empty)
INSERT INTO todos (task, status)
SELECT * FROM (SELECT 'Learn Docker basics' as task, 'completed' as status) AS tmp
WHERE NOT EXISTS (SELECT 1 FROM todos LIMIT 1);

INSERT INTO todos (task, status) VALUES
    ('Build Flask application', 'completed'),
    ('Create docker-compose.yml', 'completed'),
    ('Set up Jenkins pipeline', 'pending'),
    ('Deploy to production', 'pending')
ON DUPLICATE KEY UPDATE task=task;  -- Avoid duplicates
