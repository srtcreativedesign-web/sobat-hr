PROJECT BLUEPRINT: SOBAT (Smart Operations & Business Administrative Tool)

1. PROJECT OVERVIEW

Goal: Membangun sistem HRIS End-to-End dalam 3 bulan.

Developer Mode: Solo Developer (Speed Run).

Tech Stack (Updated):

Backend API: Laravel 11 (PHP). Dipilih karena kematangan fitur Payroll, Queue, dan Security API (Sanctum).

Web Admin Frontend: Next.js (App Router) + TypeScript.

Mobile Apps: Flutter.

Database: PostgreSQL.

Integration: Fingerprint SDK/API Integration & PDF Generator for Slip Gaji.

2. SYSTEM ARCHITECTURE & ACCESS LEVEL

A. Super Admin (Web Dashboard - Next.js)

Scope: Global Corporate Management.

Features:

Dashboard Analytics: Visualisasi turnover, heat-map absensi, status kontrak.

Employee Database: Master data, digital contract management, dokumen SP/SK.

Payroll Engine: Metriks BPJS, PPh21, kalkulasi otomatis ke Slip Gaji.

Organization: Struktur organisasi dengan dynamic approval workflow bertingkat.

Integration: Sinkronisasi data mesin fingerprint ke server PostgreSQL.

Multi-branch: Manajemen data antar cabang secara terpusat.

B. Admin Cabang / Manager (Web Dashboard - Next.js)

Scope: Branch Operations.

Features:

Shift Management: Penjadwalan roster mingguan/bulanan per cabang.

Approval Tier 1: Verifikasi awal cuti, lembur, dan reimburse sebelum diteruskan.

Monitoring: Menarik dan memantau data absensi spesifik cabang.

C. User / Staff (Mobile App - Flutter)

Scope: Employee Self-Service (ESS).

Features:

Submission: Pengajuan Cuti, Reimburse, Resign, & Lembur.

Tracking: Melihat status approval bertingkat secara real-time.

Documents: Akses dan unduh Slip Gaji (PDF).

Profile: Update data personal terbatas.

3. CORE DATA STRUCTURE (SQL RELATIONS)

AI Agent harus memastikan integritas data pada relasi berikut:

Users & Roles: RBAC (Role-Based Access Control) untuk Super Admin, Admin Cabang, dan Staff.

Employees: Data personal, posisi, gaji pokok, dan status kontrak.

Attendance: Raw logs dari fingerprint yang diproses menjadi jam kerja efektif.

Payroll: Tabel transaksi penggajian bulanan beserta komponen tunjangan/potongan.

Workflows: Tabel pengajuan (Cuti/Reimburse) dengan log approval per-level.

4. DEVELOPMENT GUIDELINES FOR AI AGENT

API-First Approach: Laravel harus menyediakan RESTful API terdokumentasi dengan Laravel Sanctum sebagai sistem autentikasi.

Shared Logic: Logika penghitungan (Payroll, Pajak) harus berada di Backend (Laravel) agar konsisten saat diakses Web maupun Mobile.

Efficiency: Gunakan Laravel Resource untuk transformasi data API yang ringan.

State Management: Gunakan Zustand di Next.js dan Provider di Flutter untuk kesederhanaan.

Repository Pattern: Terapkan di Laravel agar logika database terpisah dari Controller, memudahkan maintenance solo dev.

5. 3-MONTH MILESTONES (CRITICAL PATH)

Bulan 1: Setup Laravel API (Auth/Sanctum), Database Schema, & Master Data Karyawan (CRUD). ✅ COMPLETED

Status Update (January 6, 2026):
- ✅ Laravel 11 API fully setup with Sanctum authentication
- ✅ Complete database migrations for all tables
- ✅ 10 API Controllers created (Auth, Employee, Organization, Attendance, Shift, Request, Approval, Payroll, Role, Dashboard)
- ✅ 9 Models with complete relationships
- ✅ Repository Pattern implementation
- ✅ API Resources for consistent data transformation
- ✅ Role-based access control middleware
- ✅ Database seeders with test data
- ✅ Complete API documentation
- ✅ README with setup instructions

Files Created:
- routes/api.php (70+ endpoints)
- app/Http/Controllers/Api/* (10 controllers)
- app/Models/* (9 models)
- app/Repositories/* (2 repositories)
- app/Http/Resources/* (9 resources)
- app/Http/Middleware/CheckRole.php
- database/seeders/* (5 seeders)
- API_DOCUMENTATION.md
- SETUP_SUMMARY.md

Bulan 2: Payroll Engine (BPJS/PPh21), Fingerprint Integration, & Approval Workflow Logic.

Next Tasks for Month 2:
- Implement fingerprint device integration using Laravel Jobs
- Add DomPDF for payroll slip generation
- Enhance payroll calculation with detailed allowances/deductions
- Implement dynamic approval workflow based on organization hierarchy
- Add email notifications for approvals
- Create comprehensive unit & feature tests

Bulan 3: Flutter App Development (Submission & Slip Gaji) & Final Testing.

6. FINGERPRINT SYNC LOGIC

Menggunakan Laravel Jobs/Queue untuk menarik data dari IP mesin fingerprint secara terjadwal (misal: setiap jam 12 malam).

Normalisasi data log mentah menjadi status: Hadir, Telat, atau Alpa berdasarkan jadwal Shift karyawan.

Instruksi Khusus untuk AI: Selalu rujuk file ini sebelum membuat modul baru untuk menjaga konsistensi arsitektur antara PHP (Backend) dan JavaScript/Dart (Frontend).