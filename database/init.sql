-- =======================================================
-- Database Initialization Script
-- System: Transaksi Bahan Baku (Raw Material Inventory System)
-- =======================================================

CREATE DATABASE IF NOT EXISTS `raw_material_db` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE `raw_material_db`;

-- Drop existing tables in reverse dependency order
SET FOREIGN_KEY_CHECKS = 0;
DROP TABLE IF EXISTS `stock_movements`;
DROP TABLE IF EXISTS `goods_return_items`;
DROP TABLE IF EXISTS `goods_returns`;
DROP TABLE IF EXISTS `goods_out_items`;
DROP TABLE IF EXISTS `goods_out`;
DROP TABLE IF EXISTS `materials`;
DROP TABLE IF EXISTS `categories`;
SET FOREIGN_KEY_CHECKS = 1;

-- 1. Table: Categories
CREATE TABLE `categories` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `code` VARCHAR(20) NOT NULL UNIQUE,
    `name` VARCHAR(100) NOT NULL,
    `description` TEXT NULL,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 2. Table: Materials (Master Bahan Baku)
CREATE TABLE `materials` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `code` VARCHAR(50) NOT NULL UNIQUE,
    `name` VARCHAR(150) NOT NULL,
    `category_id` INT NOT NULL,
    `unit` VARCHAR(20) NOT NULL COMMENT 'e.g. kg, pcs, meter, liter, roll, lembar',
    `min_stock` DECIMAL(12, 2) NOT NULL DEFAULT 0.00 COMMENT 'Minimum safety stock threshold',
    `current_stock` DECIMAL(12, 2) NOT NULL DEFAULT 0.00,
    `description` TEXT NULL,
    `is_active` BOOLEAN NOT NULL DEFAULT TRUE,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT `fk_materials_category` FOREIGN KEY (`category_id`) REFERENCES `categories` (`id`) ON UPDATE CASCADE ON DELETE RESTRICT,
    INDEX `idx_materials_code` (`code`),
    INDEX `idx_materials_category` (`category_id`),
    INDEX `idx_materials_stock` (`current_stock`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 3. Table: Goods Out (Transaksi Barang Keluar)
CREATE TABLE `goods_out` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `transaction_code` VARCHAR(50) NOT NULL UNIQUE,
    `transaction_date` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `department` VARCHAR(100) NOT NULL,
    `recipient_name` VARCHAR(100) NOT NULL,
    `notes` TEXT NULL,
    `total_items` INT NOT NULL DEFAULT 0,
    `total_qty` DECIMAL(12, 2) NOT NULL DEFAULT 0.00,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX `idx_goods_out_code` (`transaction_code`),
    INDEX `idx_goods_out_date` (`transaction_date`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 4. Table: Goods Out Items (Detail Barang Keluar)
CREATE TABLE `goods_out_items` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `goods_out_id` INT NOT NULL,
    `material_id` INT NOT NULL,
    `quantity` DECIMAL(12, 2) NOT NULL,
    `unit` VARCHAR(20) NOT NULL,
    `returned_qty` DECIMAL(12, 2) NOT NULL DEFAULT 0.00 COMMENT 'Tracks how much has already been returned',
    `notes` TEXT NULL,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT `fk_goi_goods_out` FOREIGN KEY (`goods_out_id`) REFERENCES `goods_out` (`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_goi_material` FOREIGN KEY (`material_id`) REFERENCES `materials` (`id`) ON DELETE RESTRICT,
    INDEX `idx_goi_goods_out` (`goods_out_id`),
    INDEX `idx_goi_material` (`material_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 5. Table: Goods Returns (Transaksi Pengembalian Barang)
CREATE TABLE `goods_returns` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `return_code` VARCHAR(50) NOT NULL UNIQUE,
    `return_date` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `goods_out_id` INT NULL COMMENT 'Optional reference to goods out transaction',
    `returner_name` VARCHAR(100) NOT NULL,
    `department` VARCHAR(100) NOT NULL,
    `reason` VARCHAR(255) NOT NULL,
    `notes` TEXT NULL,
    `total_items` INT NOT NULL DEFAULT 0,
    `total_qty` DECIMAL(12, 2) NOT NULL DEFAULT 0.00,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT `fk_goods_returns_go` FOREIGN KEY (`goods_out_id`) REFERENCES `goods_out` (`id`) ON DELETE SET NULL,
    INDEX `idx_goods_returns_code` (`return_code`),
    INDEX `idx_goods_returns_date` (`return_date`),
    INDEX `idx_goods_returns_go` (`goods_out_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 6. Table: Goods Return Items (Detail Pengembalian Barang)
CREATE TABLE `goods_return_items` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `goods_return_id` INT NOT NULL,
    `goods_out_item_id` INT NULL COMMENT 'Optional link to specific line item from goods out',
    `material_id` INT NOT NULL,
    `quantity` DECIMAL(12, 2) NOT NULL,
    `unit` VARCHAR(20) NOT NULL,
    `condition_type` ENUM('GOOD', 'DAMAGED') NOT NULL DEFAULT 'GOOD',
    `is_restocked` BOOLEAN NOT NULL DEFAULT TRUE COMMENT 'TRUE if good condition and returned to stock',
    `notes` TEXT NULL,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT `fk_gri_return` FOREIGN KEY (`goods_return_id`) REFERENCES `goods_returns` (`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_gri_go_item` FOREIGN KEY (`goods_out_item_id`) REFERENCES `goods_out_items` (`id`) ON DELETE SET NULL,
    CONSTRAINT `fk_gri_material` FOREIGN KEY (`material_id`) REFERENCES `materials` (`id`) ON DELETE RESTRICT,
    INDEX `idx_gri_return` (`goods_return_id`),
    INDEX `idx_gri_material` (`material_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 7. Table: Stock Movements (Kartu Stok / Audit Trail Riwayat Transaksi)
CREATE TABLE `stock_movements` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `movement_code` VARCHAR(50) NOT NULL,
    `material_id` INT NOT NULL,
    `movement_type` ENUM('INITIAL', 'OUT_USAGE', 'IN_RETURN', 'ADJUSTMENT') NOT NULL,
    `reference_type` ENUM('GOODS_OUT', 'GOODS_RETURN', 'MANUAL_ADJUSTMENT', 'INITIAL_STOCK') NOT NULL,
    `reference_id` INT NULL,
    `quantity` DECIMAL(12, 2) NOT NULL COMMENT 'Negative for OUT, Positive for IN',
    `stock_before` DECIMAL(12, 2) NOT NULL,
    `stock_after` DECIMAL(12, 2) NOT NULL,
    `notes` TEXT NULL,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT `fk_sm_material` FOREIGN KEY (`material_id`) REFERENCES `materials` (`id`) ON DELETE RESTRICT,
    INDEX `idx_movement_material` (`material_id`),
    INDEX `idx_movement_type` (`movement_type`),
    INDEX `idx_movement_created` (`created_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
