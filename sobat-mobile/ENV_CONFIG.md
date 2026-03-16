
# Environment Configuration Guide

## 🚀 Cara Menggunakan

### Development Mode

1. **Cari IP Address komputer Anda:**

   **macOS/Linux:**
   ```bash
   ifconfig | grep "inet " | grep -v 127.0.0.1
   ```

   **Windows:**
   ```bash
   ipconfig | findstr /i "IPv4"
   ```

   Contoh output: `192.168.1.11`

2. **Jalankan app dengan IP Anda:**

   ```bash
   flutter run --dart-define=DEV_HOST=192.168.1.11
   ```

   Atau dengan environment flag:
   ```bash
   flutter run --dart-define=ENV=dev --dart-define=DEV_HOST=192.168.1.11
   ```

### Production Mode

```bash
flutter run --dart-define=ENV=prod
```

Atau build untuk release:
```bash
flutter build apk --release
flutter build ios --release
```

## 📝 Konfigurasi Tersedia

| Parameter | Default | Deskripsi |
|-----------|---------|-----------|
| `ENV` | `dev` | Environment mode (`dev` atau `prod`) |
| `DEV_HOST` | `192.168.1.11` | IP address komputer development |

## 🔧 VS Code Configuration (Optional)

Buat file `.vscode/launch.json` untuk memudahkan development:

```json
{
  "version": "0.2.0",
  "configurations": [
    {
      "name": "SOBAT HR - Dev",
      "request": "launch",
      "type": "dart",
      "args": [
        "--dart-define=DEV_HOST=192.168.1.11"
      ]
    },
    {
      "name": "SOBAT HR - Prod",
      "request": "launch",
      "type": "dart",
      "args": [
        "--dart-define=ENV=prod"
      ]
    }
  ]
}
```

## 📱 Build Commands

### Android APK
```bash
flutter build apk --release --dart-define=ENV=prod
```

### Android App Bundle
```bash
flutter build appbundle --release --dart-define=ENV=prod
```

### iOS
```bash
flutter build ios --release --dart-define=ENV=prod
```

## ⚠️ Troubleshooting

### "Connection refused" error
- Pastikan server backend berjalan di port 8000
- Pastikan IP address benar
- Pastikan komputer dan emulator/HP dalam satu jaringan WiFi

### "Network request failed"
- Cek firewall settings
- Pastikan backend API accessible dari browser: `http://YOUR_IP:8000/api/auth/login`

## 📋 Checklist Development

- [ ] Dapatkan IP address komputer
- [ ] Update `DEV_HOST` di command flutter run
- [ ] Test koneksi ke backend
- [ ] Pastikan emulator/device dalam satu jaringan

---

**Last Updated:** March 16, 2026
