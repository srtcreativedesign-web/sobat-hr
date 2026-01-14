-- MATIKAN FOREIGN KEY CHECK (Agar bisa truncate tabel tanpa error constraint)
SET FOREIGN_KEY_CHECKS = 0;

-- KOSONGKAN TABEL (TRUNCATE akan mereset ID kembali ke 1)
TRUNCATE TABLE approvals;
TRUNCATE TABLE attendances;
TRUNCATE TABLE employees;
TRUNCATE TABLE failed_jobs;
TRUNCATE TABLE job_batches;
TRUNCATE TABLE migrations; -- Hati-hati dgn ini, biasanya jangan dihapus jika ingin keep migration status
TRUNCATE TABLE organizations;
TRUNCATE TABLE password_reset_tokens;
TRUNCATE TABLE payrolls;
TRUNCATE TABLE personal_access_tokens;
TRUNCATE TABLE requests;
TRUNCATE TABLE role_user; -- Pivot table
TRUNCATE TABLE roles;
TRUNCATE TABLE sessions;
TRUNCATE TABLE shifts;
TRUNCATE TABLE users;

-- NYALAKAN KEMBALI FOREIGN KEY CHECK
SET FOREIGN_KEY_CHECKS = 1;

-- INFO:
-- Jika Anda menggunakan Laravel, cara LEBIH AMAN dan BERSIH adalah dengan command:
-- php artisan migrate:fresh --seed
-- (Command ini akan drop semua tabel, buat ulang dari awal, dan isi data dummy/seed)
