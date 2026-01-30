---
description: How to update API Configuration when changing Wi-Fi / Network
---

# Panduan Update Config Saat Ganti Wi-Fi

Setiap kali Anda berpindah koneksi internet (Contoh: Dari Wi-Fi Kantor ke Hotspot Pribadi), IP Address laptop Anda akan berubah. Aplikasi Mobile di HP (Fisik) tidak akan bisa menghubungi server di Laptop jika IP ini tidak diupdate.

## 1. Cek IP Address Baru
Buka Terminal baru, dan jalankan perintah:

```bash
ifconfig | grep "inet " | grep -v 127.0.0.1
```

Cari angka seperti `192.168.x.x` atau `172.x.x.x` (biasanya di baris kedua atau yang bukan `127.0.0.1`).

## 2. Update Web Admin (.env.local)
Buka file:
`sobat-web/.env.local`

Update bagian ini:
```bash
NEXT_PUBLIC_API_URL=http://[IP_BARU_ANDA]:8000/api
```
*(Jangan lupa simpan file)*

## 3. Update Mobile App (api_config.dart)
Buka file:
`sobat-mobile/lib/config/api_config.dart`

Update variabel static `_hostIp`:
```dart
static const String _hostIp = '[IP_BARU_ANDA]';
```
*(Jangan lupa simpan file)*

## 4. Restart Server (Opsional tapi Disarankan)
Jika Web Admin tidak mendeteksi perubahan, stop terminal `npm run dev` (Ctrl+C) lalu jalankan lagi.
Untuk Mobile App, Anda perlu melakukan **Hot Restart** (Cmd+Shift+F5 di VS Code) atau Re-build ulang jika masih gagal.
