# Pemetaan Struktur File Excel "payslip hans.xlsx"

File Excel ini berisi format slip gaji (payslip) dengan struktur kolom yang memiliki header gabungan (merged cells). Berikut adalah pemetaan kolom dan struktur datanya berdasarkan sampel data yang ada di dalamnya ("Gilang Ramadhan"):

## 1. Identitas Karyawan & Periode
| Nama Kolom Excel | Keterangan / Mapping | Contoh Data |
| :--- | :--- | :--- |
| `No` | Nomor urut | `1` |
| `Nama Karyawan` | Nama lengkap karyawan | `Gilang Ramadhan` |
| `periode` | Periode slip gaji (Format Date) | `2026-01-01 00:00:00` |
| `No Rekening` | Nomor rekening penerima | `7295554665` |
| `Masa Kerja` | Lama masa kerja | `2 tahun` |
| `Ket` | Keterangan tambahan | (kosong) |

## 2. Data Kehadiran (Jumlah Hari)
Header Grup: **Jumlah**
| Sub-kolom | Keterangan | Contoh Data |
| :--- | :--- | :--- |
| `Hari` | Total hari dalam periode bulan tersebut | `31` |
| `Off` | Jumlah hari libur / off | `8` |
| `Sakit` | Jumlah hari sakit | (kosong / 0) |
| `Ijin` | Jumlah hari ijin | (kosong / 0) |
| `Alfa` | Jumlah hari mangkir / tanpa keterangan | (kosong / 0) |
| `Cuti` | Jumlah hari cuti | (kosong / 0) |
| `Ada` | Hari kehadiran efektif (kerja) | `23` |

## 3. Komponen Pendapatan (Gaji & Tunjangan)
| Nama Kolom Excel | Sub-kolom (jika ada) | Keterangan | Contoh Data |
| :--- | :--- | :--- | :--- |
| `Gaji Pokok (Rp)` | - | Gaji pokok tiap bulan | `4.000.000` |
| `Tunj. Jabatan (Rp)` | - | Tunjangan terkait posisi/jabatan | `200.000` |
| `Uang Makan (Rp)` | `/ Hari` | Rate uang makan harian | `20.000` |
| | `Jumlah` | Total uang makan (`Rate` x `Hari Ada`) | `460.000` |
| `Transport (Rp)` | `/ Hari` | Rate uang transport harian | `15.000` |
| | `Jumlah` | Total transport (`Rate` x `Hari Ada`) | `345.000` |
| `Tunj. Kehadiran (Rp)` | - | Tunjangan kehadiran | `200.000` |
| `Tunj. Kesehatan (Rp)` | - | Tunjangan kesehatan | `200.000` |
| **`Total Gaji (Rp)`** | - | **Subtotal gaji & tunjangan tetap** | **`5.405.000`** |

## 4. Komponen Tambahan (Lembur & Lainnya)
| Nama Kolom Excel | Sub-kolom | Keterangan | Contoh Data |
| :--- | :--- | :--- | :--- |
| `Lembur (Rp)` | `/ Jam` | Rate lembur per jam | `15.000` |
| | `Jam` | Total jam lembur | `10` |
| | `Jumlah` | Total upah lembur (`Rate` x `Jam`) | `150.000` |
| `Bonus` | - | Bonus performa / operasional | `200.000` |
| `Insentif Lebaran` | - | Insentif hari raya (THR) | `100.000` |
| `Adj Kekurangan Gaji` | - | Penyesuaian gaji bulan sebelumnya | (kosong / 0) |
| **`Total Gaji & Bonus`** | - | **Total pendapatan kotor sebelum potongan**| **`5.855.000`** |

## 5. Komponen Potongan (Deductions)
Header Grup: **Potongan (Rp)**
| Sub-kolom | Keterangan | Contoh Data |
| :--- | :--- | :--- |
| `Kebijakan HO` | Potongan dari kebijakan Head Office | (kosong / 0) |
| `Absen 1X` | Potongan karena absen/alfa | `20.000` |
| `Terlambat` | Potongan keterlambatan | `20.000` |
| `Selisih SO` | Potongan karena selisih stock opname | (kosong / 0) |
| `Pinjaman` | Cicilan/potongan kasbon atau pinjaman | `500.000` |
| `Adm Bank` | Biaya administrasi transfer bank | `2.500` |
| `BPJS TK` | Potongan asuransi BPJS Ketenagakerjaan | `200.000` |
| **`Jumlah`** | **Total seluruh potongan** | **`742.500`** |

## 6. Penerimaan Bersih
| Nama Kolom Excel | Keterangan | Contoh Data |
| :--- | :--- | :--- |
| **`Grand Total (Rp)`** | **Take Home Pay (`Total Gaji & Bonus` - `Jumlah Potongan`)** | **`5.112.500`** |
