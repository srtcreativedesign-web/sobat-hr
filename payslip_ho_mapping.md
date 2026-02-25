# Pemetaan Struktur File Excel "payslip HO.xlsx"

File Excel ini merupakan template slip gaji (payslip) untuk unit **Head Office**. File ini memiliki struktur dua baris header untuk mengakomodasi rate harian dan total. Karena file yang ada saat ini hanya berisi template tanpa data karyawan, pemetaan dilakukan berdasarkan label kolom yang tersedia.

## 1. Identitas Karyawan
| Kolom Excel | Nama Header | Keterangan |
| :--- | :--- | :--- |
| `A` | `No` | Nomor urut |
| `B` | `NAMA` | Nama lengkap karyawan |
| `C` | `Nomor Rekening` | Nomor rekening bank karyawan |

## 2. Gaji Pokok & Kehadiran Dasar
| Kolom Excel | Header 1 | Header 2 | Keterangan |
| :--- | :--- | :--- | :--- |
| `D` | `Gaji Pokok` | - | Dasar gaji bulanan |
| `E` | `JML HR` | `MASUK` | Jumlah hari kehadiran efektif |

## 3. Tunjangan Harian (Transport & Kehadiran)
Tunjangan ini dihitung berdasarkan hari masuk (E).
| Kolom Excel | Header 1 | Header 2 | Keterangan |
| :--- | :--- | :--- | :--- |
| `F` | `transport` | `@hari` | Nilai transport per hari |
| `G` | `transport` | `total` | Total transport (`E` x `F`) |
| `H` | `Uang kehadiran` | `@hari` | Nilai uang kehadiran per hari |
| `I` | `Uang kehadiran` | `total` | Total uang kehadiran (`E` x `H`) |

## 4. Upah Lembur (Overtime)
| Kolom Excel | Header 1 | Header 2 | Keterangan |
| :--- | :--- | :--- | :--- |
| `J` | `JAM LBR` | - | Total jam lembur |
| `K` | `uang Lembur` | `@ jam` | Rate lembur per jam |
| `L` | `uang Lembur` | `total` | Total upah lembur (`J` x `K`) |

## 5. Pendapatan Lain-lain & Total Kotor
| Kolom Excel | Nama Header | Keterangan |
| :--- | :--- | :--- |
| `M` | `Total Gaji` | Subtotal pendapatan (`D + G + I + L`) |
| `N` | `Tunjangan Jabatan` | Tunjangan tetap jabatan |
| `O` | `Tunjangan` | Tunjangan lainnya |
| `P` | `Insentif Luar Kota` | Insentif dinas luar kota |
| `Q` | `Insentif Kehadiran` | Bonus kehadiran (biasanya jika full sebulan) |
| `R` | `Adj gaji` | Penyesuaian gaji (tambah/kurang) |
| `S` | `Piket dan UM sabtu` | Uang makan sabtu / uang piket |
| **`T`** | **`Gaji Diterima`** | **Total Pendapatan Kotor (`M + N + O + P + Q + R + S`)** |

## 6. Potongan (Deductions)
| Kolom Excel | Header 1 | Header 2 | Keterangan |
| :--- | :--- | :--- | :--- |
| `U` | `Potongan` | `Kasbon` | Potongan pinjaman/kasbon |
| `V` | - | `ALFA` | Potongan ketidakhadiran |
| `W` | - | `Potongan EWA` | Potongan Early Wage Access (kasbon via app) |

## 7. Penerimaan Bersih
| Kolom Excel | Header 2 | Keterangan |
| :--- | :--- | :--- |
| **`X`** | **`Net Salary`** | **Take Home Pay (`T - U - V - W`)** |
