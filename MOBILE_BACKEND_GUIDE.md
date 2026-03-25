# 📱 How Backend Works When App is Installed on Phone

## Overview

Your Flutter mobile app is a **client application** that communicates with a **PHP backend API** running on a server. The app itself doesn't contain the backend - it makes HTTP requests to a remote server.

## Current Configuration

The app is currently configured to connect to:
```
http://localhost/Salary/api
```

**⚠️ This will NOT work on a physical phone!** `localhost` refers to the device itself, not your computer.

## How It Works

### Architecture Flow:
```
[Your Phone] 
    ↓ (HTTP Requests)
[Backend Server (PHP/MySQL)]
    ↓ (Database Queries)
[MySQL Database]
```

### What Happens When You Use the App:

1. **App makes API call** → Sends HTTP request to backend URL
2. **Backend processes request** → PHP code handles the request
3. **Database query** → Backend queries MySQL database
4. **Response sent back** → JSON data returned to app
5. **App displays data** → Flutter UI updates with the response

## Two Options for Backend Setup

### Option 1: Local Development (Testing Only)

**Use this when:**
- Testing on your phone while developing
- Your computer and phone are on the same WiFi network
- XAMPP is running on your computer

**Setup Steps:**

1. **Find your computer's local IP address:**
   - Windows: Open Command Prompt, type `ipconfig`
   - Look for "IPv4 Address" (e.g., `192.168.1.100`)
   - Mac/Linux: Open Terminal, type `ifconfig` or `ip addr`

2. **Update app configuration:**
   - Open `lib/config/app_config.dart`
   - Change:
     ```dart
     static const String baseUrl = 'http://YOUR_COMPUTER_IP/Salary/api';
     ```
   - Example: `http://192.168.1.100/Salary/api`

3. **Start XAMPP:**
   - Start Apache
   - Start MySQL

4. **Configure firewall:**
   - Allow incoming connections on port 80 (or your Apache port)
   - Windows: Windows Defender Firewall → Allow an app → Apache

5. **Test connection:**
   - On your phone's browser, visit: `http://YOUR_COMPUTER_IP/Salary/api/auth/login`
   - Should see JSON response (not error)

**Limitations:**
- ❌ Only works when phone and computer are on same WiFi
- ❌ Computer must be running XAMPP
- ❌ Not suitable for production use

---

### Option 2: Remote Server (Production - Recommended)

**Use this when:**
- Deploying for real users
- Need 24/7 availability
- Multiple users need access

**Setup Steps:**

1. **Deploy backend to hosting:**
   - Upload PHP files to web hosting (e.g., InfinityFree, Hostinger)
   - Set up MySQL database
   - Configure `config/db.php` with hosting credentials

2. **Update app configuration:**
   - Open `lib/config/app_config.dart`
   - Change to your hosting URL:
     ```dart
     static const String baseUrl = 'https://yourdomain.com/api';
     ```
   - Or: `https://yourdomain.epizy.com/Salary/api`

3. **Build and install app:**
   - Build release APK: `flutter build apk --release`
   - Install on phone
   - App will connect to remote server

**Advantages:**
- ✅ Works from anywhere (internet connection required)
- ✅ 24/7 availability
- ✅ Multiple users can use simultaneously
- ✅ Professional deployment

---

## Important Notes

### Security Considerations:

1. **HTTPS in Production:**
   - For production, use HTTPS (not HTTP)
   - Update: `https://yourdomain.com/api`
   - Prevents data interception

2. **API Authentication:**
   - App uses Bearer token authentication
   - Token stored securely in phone's SharedPreferences
   - Token sent with every API request

3. **CORS Headers:**
   - Backend already configured with CORS headers
   - Allows mobile app to make requests

### Network Requirements:

- **Phone must have internet connection** (WiFi or mobile data)
- **Backend server must be accessible** from phone's network
- **Firewall must allow connections** (for local setup)

### Troubleshooting Connection Issues:

**Problem:** App shows "Network error" or can't connect

**Solutions:**
1. Check backend URL in `app_config.dart`
2. Verify backend server is running
3. Test API in browser: `http://YOUR_URL/api/auth/login`
4. Check phone's internet connection
5. Verify firewall settings (for local setup)
6. Check if using HTTP vs HTTPS correctly

---

## Quick Setup Checklist

### For Local Testing:
- [ ] Find computer's IP address
- [ ] Update `app_config.dart` with IP
- [ ] Start XAMPP (Apache + MySQL)
- [ ] Configure firewall
- [ ] Test API in phone browser
- [ ] Build and install app

### For Production:
- [ ] Deploy backend to hosting
- [ ] Set up database on hosting
- [ ] Update `app_config.dart` with hosting URL
- [ ] Use HTTPS (not HTTP)
- [ ] Build release APK
- [ ] Test on phone

---

## Example API Flow

When you login in the app:

1. **App sends:**
   ```
   POST http://your-server.com/api/auth/login
   Body: {"username": "admin", "password": "admin123"}
   ```

2. **Backend receives:**
   - PHP `ApiAuthController` processes request
   - Validates credentials against database
   - Generates JWT token

3. **Backend responds:**
   ```json
   {
     "status": "success",
     "token": "eyJhbGciOiJIUzI1NiIs...",
     "user": {...}
   }
   ```

4. **App stores token:**
   - Saves token in SharedPreferences
   - Uses token for all future requests

5. **Future requests:**
   ```
   GET http://your-server.com/api/staff/list
   Headers: Authorization: Bearer eyJhbGciOiJIUzI1NiIs...
   ```

---

## Summary

**The backend is NOT installed on your phone.** The app connects to a backend server (either your local computer with XAMPP, or a remote hosting server) via HTTP/HTTPS requests. The backend handles all database operations and business logic, while the app only displays the UI and sends/receives data.

**For production use, deploy the backend to a web hosting service and update the app's API URL accordingly.**

