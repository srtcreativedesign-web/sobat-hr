# SOBAT HR Mobile

Mobile application untuk SOBAT HR - Human Resource Management System

## Tech Stack

- **Framework**: Flutter 3.38.1
- **Language**: Dart 3.10.0
- **State Management**: Provider
- **API Integration**: dio
- **Local Storage**: flutter_secure_storage
- **Authentication**: Bearer Token (Sanctum)

## Project Structure

```
lib/
├── main.dart                 # Entry point
├── config/                   # Configuration files
│   ├── api_config.dart      # API endpoints
│   ├── theme.dart           # App theme
│   └── routes.dart          # Route definitions
├── models/                   # Data models
│   ├── user.dart
│   ├── employee.dart
│   └── payroll.dart
├── services/                 # API services
│   ├── auth_service.dart
│   ├── api_service.dart
│   └── storage_service.dart
├── providers/                # State management
│   └── auth_provider.dart
├── screens/                  # UI screens
│   ├── auth/
│   │   ├── login_screen.dart
│   │   └── splash_screen.dart
│   ├── dashboard/
│   │   └── dashboard_screen.dart
│   ├── attendance/
│   ├── leave/
│   └── payroll/
└── widgets/                  # Reusable widgets
    ├── custom_button.dart
    ├── custom_text_field.dart
    └── loading_indicator.dart
```

## Design System

### Colors (Match with Web App)
- Primary: `#1A4D2E` (Forest Green)
- Secondary: `#49FFB8` (Neon Mint)
- Background: `#FFFFFF`
- Text: `#1F2937`

## Getting Started

### Installation

1. Install dependencies
```bash
flutter pub get
```

2. Run the app
```bash
flutter run
```

### Build

```bash
# Android APK
flutter build apk --release

# iOS
flutter build ios --release
```

## API Integration

Backend API: `http://localhost:8000/api` (Development)

## Features Roadmap

- [ ] Authentication (Login/Logout)
- [ ] Dashboard Overview
- [ ] Attendance Check-in/Check-out
- [ ] Leave Request
- [ ] Payroll View
- [ ] Push Notifications

## License

Proprietary - SOBAT HR © 2026
