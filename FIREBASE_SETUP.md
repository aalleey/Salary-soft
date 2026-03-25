# 🔥 Firebase Setup Guide for SalarySoft App

## Overview

Your app has been fully migrated to use Firebase instead of PHP/MySQL backend. This means:
- ✅ **No server needed** - Everything runs on Firebase
- ✅ **Works anywhere** - Phone just needs internet connection
- ✅ **Real-time updates** - Data syncs automatically
- ✅ **Scalable** - Firebase handles all the backend infrastructure

## Prerequisites

1. **Firebase Account** - Sign up at [firebase.google.com](https://firebase.google.com)
2. **Flutter SDK** - Already installed
3. **Android Studio** or **VS Code** - For development

## Step-by-Step Setup

### Step 1: Create Firebase Project

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Click **"Add project"** or **"Create a project"**
3. Enter project name: `salarysoft` (or any name you prefer)
4. Disable Google Analytics (optional, you can enable later)
5. Click **"Create project"**
6. Wait for project creation (takes ~30 seconds)

### Step 2: Add Android App to Firebase

1. In Firebase Console, click the **Android icon** (or "Add app")
2. Fill in the details:
   - **Android package name**: `com.example.salary_app` (check `android/app/build.gradle.kts` for actual package name)
   - **App nickname**: `SalarySoft Android` (optional)
   - **Debug signing certificate SHA-1**: (optional for now)
3. Click **"Register app"**
4. Download `google-services.json` file
5. Place it in: `salary_app/android/app/google-services.json`

### Step 3: Configure Android Build

1. Open `salary_app/android/build.gradle.kts`
2. Add to `dependencies`:
   ```kotlin
   dependencies {
       classpath("com.google.gms:google-services:4.4.0")
   }
   ```

3. Open `salary_app/android/app/build.gradle.kts`
4. Add at the top (after plugins):
   ```kotlin
   plugins {
       id("com.android.application")
       id("kotlin-android")
       id("dev.flutter.flutter-gradle-plugin")
       id("com.google.gms.google-services")  // Add this line
   }
   ```

### Step 4: Enable Firebase Services

1. In Firebase Console, go to **Authentication**
2. Click **"Get started"**
3. Enable **Email/Password** provider
4. Click **"Save"**

5. Go to **Firestore Database**
6. Click **"Create database"**
7. Choose **"Start in test mode"** (for development)
8. Select a location (choose closest to you)
9. Click **"Enable"**

### Step 5: Create Firestore Collections

Your app uses these collections:
- `users` - User accounts
- `staff` - Staff members
- `attendance` - Attendance records
- `salaries` - Salary records
- `advances` - Advance payments

**Collections will be created automatically** when you first use the app, but you can create them manually:

1. Go to **Firestore Database** in Firebase Console
2. Click **"Start collection"**
3. Create each collection (they'll be empty initially)

### Step 6: Create Initial Admin User

You need to create the first admin user in Firestore:

1. Go to **Firestore Database** in Firebase Console
2. Click **"Start collection"** (if collections don't exist)
3. Collection ID: `users`
4. Click **"Next"**
5. Document ID: Click **"Auto-ID"** (or use a custom ID)
6. Add these fields:
   ```
   Field          Type        Value
   username       string      admin
   email          string      admin@example.com
   password       string      admin123
   role           string      admin
   campus         string      (leave empty or add a campus name)
   ```
7. Click **"Save"**

8. Now go to **Authentication** in Firebase Console
9. Click **"Add user"**
10. Email: `admin@example.com`
11. Password: `admin123`
12. Click **"Add user"**

### Step 7: Install Dependencies

Run in terminal:
```bash
cd salary_app
flutter pub get
```

### Step 8: Run the App

```bash
flutter run
```

## Default Login Credentials

- **Username**: `admin`
- **Password**: `admin123`

⚠️ **Change these credentials after first login!**

## Firestore Security Rules

For development, use these rules (in Firebase Console → Firestore → Rules):

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Allow read/write access to all documents (for development only)
    match /{document=**} {
      allow read, write: if request.auth != null;
    }
  }
}
```

**For production**, create proper security rules based on user roles.

## Troubleshooting

### Error: "MissingPluginException"
- Run: `flutter clean`
- Run: `flutter pub get`
- Restart the app

### Error: "PlatformException"
- Make sure `google-services.json` is in `android/app/` folder
- Check that package name matches in Firebase Console

### Can't login
- Verify user exists in both Firestore `users` collection AND Authentication
- Check that email and password match exactly
- Make sure Email/Password auth is enabled in Firebase Console

### Data not showing
- Check Firestore Database - collections should exist
- Verify security rules allow read access
- Check internet connection

## Next Steps

1. **Add more users**: Create users in both Firestore and Authentication
2. **Set up security rules**: Create proper access control
3. **Enable offline persistence**: App will work offline (already configured)
4. **Add data validation**: Use Cloud Functions for server-side validation

## Production Checklist

Before deploying to production:

- [ ] Update Firestore security rules
- [ ] Change default admin password
- [ ] Enable Firebase App Check
- [ ] Set up proper error logging
- [ ] Configure backup strategy
- [ ] Test on multiple devices
- [ ] Set up monitoring/alerts

## Support

If you encounter issues:
1. Check Firebase Console for errors
2. Check Flutter logs: `flutter run -v`
3. Verify all dependencies are installed
4. Ensure internet connection is working

---

**Your app is now fully functional with Firebase!** 🎉

No need for XAMPP, PHP, or MySQL. Everything runs on Firebase's cloud infrastructure.

