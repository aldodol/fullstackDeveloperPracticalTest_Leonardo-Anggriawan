# Dokumentasi REST API — Sistem Transaksi Bahan Baku

Dokumentasi lengkap antarmuka pemrograman aplikasi (REST API) untuk sistem pengelolaan persediaan bahan baku (Studi Kasus 4).

- **Base URL (Local):** `http://localhost:5000/api`
- **Swagger UI Interactive:** `http://localhost:5000/api-docs`
- **OpenAPI 3.0 Specification JSON:** `http://localhost:5000/api-docs.json`
- **Healthcheck:** `http://localhost:5000/health`

---

## Standar Format Respons

Semua endpoint menghasilkan format JSON standar yang konsisten:

### Respons Sukses (HTTP 200 / 201)
```json
{
  "success": true,
  "message": "Pesan deskriptif sukses",
  "data": { ... }
}
```

### Respons Gagal (HTTP 400 / 404 / 409 / 500)
```json
{
  "success": false,
  "message": "Pesan deskriptif kesalahan",
  "errors": [
    {
      "field": "nama_field",
      "message": "Detail aturan validasi yang dilanggar"
    }
  ]
}
```

---

## Ringkasan Endpoint

| Modul | Method | Endpoint | Deskripsi |
| :--- | :--- | :--- | :--- |
| **Dashboard & Stok** | `GET` | `/stock/overview` | Ringkasan metrik KPI & alert stok kritis |
| | `GET` | `/stock/movements` | Kartu stok & riwayat seluruh mutasi |
| | `GET` | `/stock/materials/:id/ledger` | Kartu stok per spesifik material |
| **Master Bahan Baku** | `GET` | `/materials` | Daftar master bahan baku + filter |
| | `POST` | `/materials` | Tambah bahan baku baru (+ saldo awal) |
| | `GET` | `/materials/:id` | Detail spesifik bahan baku |
| | `PUT` | `/materials/:id` | Perbarui data bahan baku |
| | `DELETE` | `/materials/:id` | Hapus / nonaktifkan bahan baku |
| | `POST` | `/materials/:id/adjust-stock` | Penyesuaian stok manual / opname |
| **Barang Keluar** | `GET` | `/goods-out` | Daftar transaksi barang keluar |
| | `POST` | `/goods-out` | Buat transaksi barang keluar (potong stok) |
| | `GET` | `/goods-out/:id` | Detail transaksi barang keluar & line items |
| **Pengembalian** | `GET` | `/goods-returns` | Daftar transaksi retur barang |
| | `POST` | `/goods-returns` | Buat transaksi retur (tambah stok kembali) |
| | `GET` | `/goods-returns/:id` | Detail transaksi retur barang |
| **Kategori** | `GET` | `/categories` | Daftar kategori bahan baku |
| | `POST` | `/categories` | Tambah kategori baru |

---

## 1. Master Bahan Baku

### 1.1 `GET /materials`
Mendapatkan daftar seluruh bahan baku dengan parameter filter dinamis.

**Query Parameters:**
- `search` (string): Pencarian berdasarkan kode, nama, atau deskripsi.
- `category_id` (int): Filter berdasarkan ID kategori.
- `stock_status` (string): Filter status persediaan: `all`, `normal`, `low_stock`, `out_of_stock`.
- `is_active` (string, default `true`): `true`, `false`, `all`.

**Contoh Response:**
```json
{
  "success": true,
  "message": "Berhasil mengambil daftar bahan baku",
  "data": [
    {
      "id": 1,
      "code": "RM-MET-001",
      "name": "Plat Baja SPCC 1.2mm",
      "category_id": 1,
      "category_name": "Logam & Besi",
      "category_code": "CAT-MET",
      "unit": "lembar",
      "min_stock": 25.0,
      "current_stock": 150.0,
      "description": "Ukuran standard 4x8 feet",
      "is_active": 1,
      "stock_status": "NORMAL"
    }
  ]
}
```

### 1.2 `POST /materials`
Menambahkan data bahan baku baru. Jika `initial_stock` > 0, sistem secara otomatis mencatat ke kartu mutasi stok (`stock_movements`) bertipe `INITIAL`.

**Request Body:**
```json
{
  "code": "RM-MET-004",
  "name": "Aluminium Sheet 1.5mm",
  "category_id": 1,
  "unit": "lembar",
  "min_stock": 20,
  "initial_stock": 100,
  "description": "Grade 5052 tahan karat"
}
```

---

## 2. Transaksi Barang Keluar (Goods Out)

### 2.1 `POST /goods-out`
Memproses pengeluaran bahan baku untuk produksi dengan garansi **ACID Transaction**:
1. Mengunci baris material (`SELECT ... FOR UPDATE`).
2. Validasi apakah `current_stock >= quantity`. Jika tidak, transaksi ditolak dan dibatalkan (rollback).
3. Mengurangi `current_stock` secara otomatis.
4. Mencatat ke `stock_movements` (jumlah bernilai negatif).

**Request Body:**
```json
{
  "department": "Divisi Fabrikasi Logam",
  "recipient_name": "Budi Santoso",
  "notes": "Pengambilan material untuk rangka konveyor",
  "items": [
    {
      "material_id": 1,
      "quantity": 10,
      "notes": "Pemotongan panel penutup"
    },
    {
      "material_id": 2,
      "quantity": 2,
      "notes": "Tiang penyangga"
    }
  ]
}
```

**Contoh Response Sukses (201 Created):**
```json
{
  "success": true,
  "message": "Transaksi barang keluar berhasil diproses",
  "data": {
    "id": 3,
    "transaction_code": "OUT-20261024-0003",
    "transaction_date": "2026-10-24T15:30:00.000Z",
    "department": "Divisi Fabrikasi Logam",
    "recipient_name": "Budi Santoso",
    "total_items": 2,
    "total_qty": 12.0,
    "items": [
      {
        "id": 5,
        "material_id": 1,
        "material_name": "Plat Baja SPCC 1.2mm",
        "quantity": 10.0,
        "unit": "lembar",
        "returned_qty": 0.0,
        "returnable_qty": 10.0
      }
    ]
  }
}
```

---

## 3. Transaksi Pengembalian Barang (Goods Return)

### 3.1 `POST /goods-returns`
Memproses pengembalian sisa bahan baku atau material yang tidak terpakai:
1. Jika terhubung ke `goods_out_id`, memvalidasi kuota sisa yang dapat dikembalikan (`returnQty <= quantity - returned_qty`).
2. Jika `condition_type == 'GOOD'` dan `is_restocked == true`, stok material bertambah kembali dan dicatat ke `stock_movements`.
3. Jika `condition_type == 'DAMAGED'`, tercatat sebagai barang afval/rusak tanpa mencemari stok aktif.

**Request Body:**
```json
{
  "goods_out_id": 1,
  "returner_name": "Budi Santoso",
  "department": "Divisi Fabrikasi Logam",
  "reason": "Sisa Pemakaian Produksi",
  "notes": "Bahan sisa pemotongan dalam kondisi baik",
  "items": [
    {
      "material_id": 1,
      "goods_out_item_id": 1,
      "quantity": 2,
      "condition_type": "GOOD",
      "is_restocked": true,
      "notes": "Kondisi utuh dan mulus"
    }
  ]
}
```

---

## 4. Stok Terkini & Riwayat Transaksi (Kartu Stok)

### 4.1 `GET /stock/overview`
Mengambil statistik KPI dan daftar bahan baku berstatus stok kritis (`current_stock <= min_stock`).

### 4.2 `GET /stock/movements`
Audit trail lengkap pergerakan buku besar persediaan.

**Query Parameters:**
- `material_id` (int): Filter material.
- `movement_type` (string): `INITIAL`, `OUT_USAGE`, `IN_RETURN`, `ADJUSTMENT`.
- `startDate` (YYYY-MM-DD)
- `endDate` (YYYY-MM-DD)
- `search` (string)
