-- =======================================================
-- Database Seeder Script
-- System: Transaksi Bahan Baku (Raw Material Inventory System)
-- =======================================================

USE `raw_material_db`;

-- Insert Categories
INSERT INTO `categories` (`id`, `code`, `name`, `description`) VALUES
(1, 'CAT-MET', 'Logam & Besi', 'Bahan baku lembaran logam, pipa, kawat, dan profil baja'),
(2, 'CAT-PLA', 'Plastik & Polimer', 'Biji plastik, lembaran akrilik, dan resin termoplastik'),
(3, 'CAT-TEX', 'Tekstil & Serat', 'Kain katun, kanvas, poliester, benang, dan serat kain'),
(4, 'CAT-CHM', 'Bahan Kimia & Perekat', 'Lem industri, cat pelapis, thinner, resin, dan hardener'),
(5, 'CAT-WD',  'Kayu & Olahan', 'Kayu solid, triplek, MDF, dan veneer');

-- Insert Raw Materials (Master Bahan Baku)
INSERT INTO `materials` (`id`, `code`, `name`, `category_id`, `unit`, `min_stock`, `current_stock`, `description`, `is_active`) VALUES
(1, 'RM-MET-001', 'Plat Baja SPCC 1.2mm', 1, 'lembar', 25.00, 150.00, 'Ukuran standard 4x8 feet, kualitas stamping', TRUE),
(2, 'RM-MET-002', 'Pipa Stainless Steel SUS 304 1 Inch', 1, 'batang', 15.00, 45.00, 'Panjang standard 6 meter per batang', TRUE),
(3, 'RM-MET-003', 'Kawat Las TIG ER70S-6 2.4mm', 1, 'kg', 20.00, 8.00, 'Kawat las mig/tig baja karbon (LOW STOCK)', TRUE),
(4, 'RM-PLA-001', 'Biji Plastik Polypropylene (PP) Putih', 2, 'kg', 100.00, 500.00, 'Grade injection molding kualitas industri', TRUE),
(5, 'RM-PLA-002', 'Lembaran Akrilik Bening 3mm (122x244)', 2, 'lembar', 10.00, 4.00, 'Akrilik transparan protektif (LOW STOCK)', TRUE),
(6, 'RM-TEX-001', 'Kain Katun Combed 30s Reaktif (Hitam)', 3, 'roll', 10.00, 32.00, 'Gramasi 140-150 gsm, lebar 42 inch tubular', TRUE),
(7, 'RM-TEX-002', 'Benang Jahit Poliester No. 40/2', 3, 'pcs', 50.00, 240.00, 'Cone benang 5000 yard warna hitam', TRUE),
(8, 'RM-CHM-001', 'Epoxy Resin & Hardener Clear Casting', 4, 'liter', 15.00, 60.00, 'Rasio 2:1 formula bening anti-yellowing', TRUE),
(9, 'RM-CHM-002', 'Thinner Polyurethane Super Gloss', 4, 'liter', 30.00, 12.00, 'Pelarut cat PU industri cepat kering (LOW STOCK)', TRUE),
(10, 'RM-WD-001',  'Plywood Meranti 18mm (122x244)', 5, 'lembar', 20.00, 80.00, 'Lapisan meranti surface halus tahan lembab', TRUE);

-- Initial Stock Movements Log
INSERT INTO `stock_movements` (`movement_code`, `material_id`, `movement_type`, `reference_type`, `reference_id`, `quantity`, `stock_before`, `stock_after`, `notes`, `created_at`) VALUES
('MOV-INIT-001', 1, 'INITIAL', 'INITIAL_STOCK', NULL, 180.00, 0.00, 180.00, 'Saldo Awal Stok Gudang', NOW() - INTERVAL 5 DAY),
('MOV-INIT-002', 2, 'INITIAL', 'INITIAL_STOCK', NULL, 50.00, 0.00, 50.00, 'Saldo Awal Stok Gudang', NOW() - INTERVAL 5 DAY),
('MOV-INIT-003', 3, 'INITIAL', 'INITIAL_STOCK', NULL, 15.00, 0.00, 15.00, 'Saldo Awal Stok Gudang', NOW() - INTERVAL 5 DAY),
('MOV-INIT-004', 4, 'INITIAL', 'INITIAL_STOCK', NULL, 600.00, 0.00, 600.00, 'Saldo Awal Stok Gudang', NOW() - INTERVAL 5 DAY),
('MOV-INIT-005', 5, 'INITIAL', 'INITIAL_STOCK', NULL, 10.00, 0.00, 10.00, 'Saldo Awal Stok Gudang', NOW() - INTERVAL 5 DAY);

-- Sample Transaction 1: Goods Out (Barang Keluar)
INSERT INTO `goods_out` (`id`, `transaction_code`, `transaction_date`, `department`, `recipient_name`, `notes`, `total_items`, `total_qty`, `created_at`) VALUES
(1, 'OUT-20261020-0001', NOW() - INTERVAL 3 DAY, 'Divisi Fabrikasi Logam', 'Budi Santoso', 'Pengambilan material rangka mesin conveyor', 2, 35.00, NOW() - INTERVAL 3 DAY);

INSERT INTO `goods_out_items` (`id`, `goods_out_id`, `material_id`, `quantity`, `unit`, `returned_qty`, `notes`) VALUES
(1, 1, 1, 30.00, 'lembar', 5.00, 'Pemotongan panel bodi conveyor'),
(2, 1, 2, 5.00, 'batang', 0.00, 'Rangka tiang penyangga');

-- Stock Movements for Goods Out 1
INSERT INTO `stock_movements` (`movement_code`, `material_id`, `movement_type`, `reference_type`, `reference_id`, `quantity`, `stock_before`, `stock_after`, `notes`, `created_at`) VALUES
('MOV-OUT-001', 1, 'OUT_USAGE', 'GOODS_OUT', 1, -30.00, 180.00, 150.00, 'Keluar untuk OUT-20261020-0001 - Budi Santoso', NOW() - INTERVAL 3 DAY),
('MOV-OUT-002', 2, 'OUT_USAGE', 'GOODS_OUT', 1, -5.00, 50.00, 45.00, 'Keluar untuk OUT-20261020-0001 - Budi Santoso', NOW() - INTERVAL 3 DAY);

-- Sample Transaction 2: Goods Return (Pengembalian Barang Sisa Produksi)
INSERT INTO `goods_returns` (`id`, `return_code`, `return_date`, `goods_out_id`, `returner_name`, `department`, `reason`, `notes`, `total_items`, `total_qty`, `created_at`) VALUES
(1, 'RET-20261021-0001', NOW() - INTERVAL 2 DAY, 1, 'Budi Santoso', 'Divisi Fabrikasi Logam', 'Sisa Pemakaian Produksi', 'Kelebihan estimasi potong plat bodi', 1, 5.00, NOW() - INTERVAL 2 DAY);

INSERT INTO `goods_return_items` (`id`, `goods_return_id`, `goods_out_item_id`, `material_id`, `quantity`, `unit`, `condition_type`, `is_restocked`, `notes`) VALUES
(1, 1, 1, 1, 5.00, 'lembar', 'GOOD', TRUE, 'Kondisi mulus dan utuh kembali ke rak penyimpanan');

-- Stock Movement for Return 1 (Stock went back up from 145 to 150)
INSERT INTO `stock_movements` (`movement_code`, `material_id`, `movement_type`, `reference_type`, `reference_id`, `quantity`, `stock_before`, `stock_after`, `notes`, `created_at`) VALUES
('MOV-RET-001', 1, 'IN_RETURN', 'GOODS_RETURN', 1, 5.00, 145.00, 150.00, 'Pengembalian dari RET-20261021-0001 (Ref OUT-20261020-0001)', NOW() - INTERVAL 2 DAY);

-- Sample Transaction 3: Another Goods Out
INSERT INTO `goods_out` (`id`, `transaction_code`, `transaction_date`, `department`, `recipient_name`, `notes`, `total_items`, `total_qty`, `created_at`) VALUES
(2, 'OUT-20261022-0002', NOW() - INTERVAL 1 DAY, 'Divisi Cetak Plastik & Akrilik', 'Dewi Lestari', 'Produksi display acrylic holder', 2, 106.00, NOW() - INTERVAL 1 DAY);

INSERT INTO `goods_out_items` (`id`, `goods_out_id`, `material_id`, `quantity`, `unit`, `returned_qty`, `notes`) VALUES
(3, 2, 4, 100.00, 'kg', 0.00, 'Biji plastik untuk injection'),
(4, 2, 5, 6.00, 'lembar', 0.00, 'Pemotongan laser display');

INSERT INTO `stock_movements` (`movement_code`, `material_id`, `movement_type`, `reference_type`, `reference_id`, `quantity`, `stock_before`, `stock_after`, `notes`, `created_at`) VALUES
('MOV-OUT-003', 4, 'OUT_USAGE', 'GOODS_OUT', 2, -100.00, 600.00, 500.00, 'Keluar untuk OUT-20261022-0002 - Dewi Lestari', NOW() - INTERVAL 1 DAY),
('MOV-OUT-004', 5, 'OUT_USAGE', 'GOODS_OUT', 2, -6.00, 10.00, 4.00, 'Keluar untuk OUT-20261022-0002 - Dewi Lestari', NOW() - INTERVAL 1 DAY);
