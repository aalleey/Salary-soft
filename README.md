# SalarySoft Mobile App

A modern Flutter mobile application for employee salary management, built with Material Design 3.

## Features

- 🔐 **Secure Authentication** - Token-based login system
- 📊 **Dashboard** - Real-time stats and overview
- 👥 **Staff Management** - View and manage staff members
- 📅 **Attendance Tracking** - Mark and track attendance
- 💰 **Salary Calculations** - Automated salary processing
- 📈 **Reports** - Generate salary reports
- 🎨 **Modern UI** - Beautiful Material Design 3 interface

## Screenshots

_Coming soon..._

## Requirements

- Flutter SDK (3.10.0 or higher)
- Android Studio / VS Code
- Android device or emulator (API 21+)
- Backend API running (PHP/MySQL)

## Installation

### 1. Clone or navigate to the project
```bash
cd c:\xamppp\htdocs\Salary\salary_app
```

### 2. Install dependencies
```bash
flutter pub get
```

### 3. Configure API URL
Open `lib/config/app_config.dart` and update the `baseUrl`:

```dart
static const String baseUrl = 'http://YOUR_SERVER_IP/Salary/api';
```

**For testing on a physical device:**
- Use your computer's local IP address (e.g., `http://192.168.1.100/Salary/api`)
- Not `localhost` or `127.0.0.1` (these refer to the device itself)

**For emulator:**
- Use `http://10.0.2.2/Salary/api` (Android emulator's alias for host machine)

### 4. Run the app
```bash
flutter run
```

## Building for Production

### Generate Release APK
```bash
flutter build apk --release
```

The APK will be located at: `build/app/outputs/flutter-apk/app-release.apk`

### Generate App Bundle (for Play Store)
```bash
flutter build appbundle --release
```

## Project Structure

```
lib/
├── config/              # App configuration and theme
│   ├── app_config.dart  # API URL and constants
│   └── theme.dart       # Material Design theme
├── models/              # Data models
│   ├── user.dart
│   └── staff.dart
├── services/            # Business logic
│   ├── api_service.dart    # HTTP client
│   └── auth_service.dart   # Authentication
├── providers/           # State management
│   └── auth_provider.dart
├── screens/             # UI screens
│   ├── splash_screen.dart
│   ├── login_screen.dart
│   ├── dashboard_screen.dart
│   └── staff_list_screen.dart
├── widgets/             # Reusable components
└── main.dart            # App entry point
```

## Dependencies

- `http` - API communication
- `provider` - State management
- `shared_preferences` - Local storage
- `google_fonts` - Custom fonts
- `intl` - Date/number formatting
- `fl_chart` - Charts and graphs

## Default Credentials

- **Username:** admin
- **Password:** admin123

⚠️ Change these credentials after first login in production!

## Troubleshooting

### Cannot connect to API
- Check that XAMPP is running (Apache + MySQL)
- Verify the API URL in `app_config.dart`
- For physical device, use computer's local IP
- Check firewall settings

### Build failures
```bash
flutter clean
flutter pub get
flutter run
```

### Hot reload not working
Stop the app and run again with:
```bash
flutter run --hot
```

## Development

### Adding new screens
1. Create screen file in `lib/screens/`
2. Add routing in navigation logic
3. Update providers if needed

### Adding new API endpoints
1. Create method in `lib/services/api_service.dart`
2. Add corresponding method in specific service
3. Update UI to consume the data

## Support

For issues or questions, refer to the main project documentation.

## License

Same as the main SalarySoft project.
