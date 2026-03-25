# 🚀 Quick Start - Firebase Setup

## Before You Start

Your app is now configured to use Firebase! Follow these steps to get it running:

## Step 1: Create Firebase Project (5 minutes)

1. Go to https://console.firebase.google.com/
2. Click **"Add project"**
3. Name it: `salarysoft` (or any name)
4. Click through the setup (disable Analytics if you want)
5. Click **"Create project"**

## Step 2: Add Android App (2 minutes)

1. In Firebase Console, click the **Android icon** (📱)
2. **Package name**: `com.example.salary_app`
3. **App nickname**: `SalarySoft` (optional)
4. Click **"Register app"**
5. **Download** `google-services.json`
6. **Place it here**: `salary_app/android/app/google-services.json`

## Step 3: Enable Services (3 minutes)

### Enable Authentication:
1. Go to **Authentication** → **Get started**
2. Click **"Email/Password"**
3. Enable it and click **"Save"**

### Enable Firestore:
1. Go to **Firestore Database** → **Create database**
2. Choose **"Start in test mode"**
3. Select location (closest to you)
4. Click **"Enable"**

## Step 4: Create Admin User (2 minutes)

### In Firestore:
1. Go to **Firestore Database**
2. Click **"Start collection"**
3. Collection ID: `users`
4. Document ID: Click **"Auto-ID"**
5. Add fields:
   - `username` (string): `admin`
   - `email` (string): `admin@example.com`
   - `password` (string): `admin123`
   - `role` (string): `admin`
6. Click **"Save"**

### In Authentication:
1. Go to **Authentication** → **Users**
2. Click **"Add user"**
3. Email: `admin@example.com`
4. Password: `admin123`
5. Click **"Add user"**

## Step 5: Run the App

```bash
cd salary_app
flutter pub get
flutter run
```

## Login Credentials

- **Username**: `admin`
- **Password**: `admin123`

## That's It! 🎉

Your app should now work with Firebase. No PHP, no MySQL, no server needed!

## Troubleshooting

**Error: "MissingPluginException"**
```bash
flutter clean
flutter pub get
flutter run
```

**Error: "google-services.json not found"**
- Make sure the file is in `android/app/google-services.json`
- Check the file name is exactly `google-services.json`

**Can't login**
- Check user exists in both Firestore AND Authentication
- Make sure Email/Password auth is enabled

---

For detailed setup, see `FIREBASE_SETUP.md`

