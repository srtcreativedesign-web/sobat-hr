---
description: How to deploy latest code to production server
---
// turbo-all

# Deploy to Production

## Prerequisites
- SSH access to server: `ssh sobatadmin@202.10.42.144`
- Git repository up to date

## Steps

### 1. Commit and Push Local Changes
```bash
cd /Applications/XAMPP/xamppfiles/htdocs/sobat-hr
git add .
git commit -m "your commit message"
git push origin main
```

### 2. SSH into Server
```bash
ssh sobatadmin@202.10.42.144
```

### 3. Deploy Backend API
```bash
cd /var/www/sobat-hr/sobat-api
git pull origin main
php artisan migrate --force
php artisan config:clear
php artisan cache:clear
```

### 4. Deploy Frontend Web
```bash
cd /var/www/sobat-hr/sobat-web
git pull origin main
npm run build
pm2 restart sobat-web
```

### 5. Verify Deployment
```bash
# Check API
curl -s https://api.sobat-hr.com/api | head -5

# Check Web
curl -I https://sobat-hr.com 2>/dev/null | head -3

# Check PM2
pm2 status
```

### 6. Build Mobile for Production (Optional - from laptop)
```bash
cd /Applications/XAMPP/xamppfiles/htdocs/sobat-hr/sobat-mobile

# Android APK
flutter build apk --dart-define=ENV=prod

# iOS
flutter build ios --dart-define=ENV=prod
```
