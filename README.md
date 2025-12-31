# Cafe Utarite Database Management System (MySQL/MariaDB)
**POS • Payments • Inventory • Purchasing • HR • Audit Logging**  
Source dump: dump/cafe_utarite.sql (phpMyAdmin SQL Dump v5.2.1)

## Overview
Repository ini berisi **SQL dump** database Cafe Utarite untuk sistem operasional cafe, mencakup:
- **POS (Orders)**: pelanggan, pesanan, detail_pesanan
- **Payments**: pembayaran + detail metode (tunai/non_tunai)
- **Inventory**: produk, jenis_produk, gudang + item kategori (bah_makanan, minuman, peralatan)
- **Purchasing**: supplier, pembelian, detail_pembelian
- **HR**: karyawan + subtype (tetap, part_time)
- **Audit Logging**: audit_event_log (permanen) + audit_event_unlog (sementara/MEMORY)

---

## Quick Facts 
- Dump tool: **phpMyAdmin SQL Dump v5.2.1**
- Database name shown in dump header: **`cafe utarite benar`**
- Tables: **20**
- Triggers: **5**
- Foreign Keys: **18**
- Charset/Collation: **utf8mb4 / utf8mb4_general_ci**
- Engines:
  - **InnoDB** (19 tables)
  - **MEMORY** (1 table: `audit_event_unlog`)
- Stored Procedures: **none**
- Functions: **none**
- Views: **none**

---

## Repo Structure 
```
Cafe-Utarite-Database-Management-System/
├─ dump/
│ └─ cafe_utarite.sql
└─ README.md
```

---

## How to Import

### Option A — phpMyAdmin
1. Create database (contoh): `cafe_utarite_benar`
2. Pilih database → tab **Import**
3. Upload file: `dump/cafe_utarite.sql`
4. Klik **Go**

### Option B — MySQL CLI
Create database (disarankan pakai nama tanpa spasi):
```bash
mysql -u root -p -e "CREATE DATABASE IF NOT EXISTS cafe_utarite_benar CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;"
```
### Import:
```python
 mysql -u root -p cafe_utarite_benar < dump/cafe_utarite.sql
```

### Quick verify:
```python
SHOW TABLES;
SELECT COUNT(*) FROM pesanan;
SELECT COUNT(*) FROM pembayaran;
SELECT COUNT(*) FROM produk;
```


