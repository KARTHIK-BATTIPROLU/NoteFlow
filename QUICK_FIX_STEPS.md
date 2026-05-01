# Quick Fix: Upload Connection Timeout

## Problem
The app can't connect to the backend server at `http://192.168.0.16:8000`

Error: `Connection timed out`

## Solutions (Try in Order)

### Solution 1: Start the Backend Server ⭐ (Most Likely)

1. **Open a new terminal/command prompt**
2. **Navigate to the backend folder:**
   ```bash
   cd backend
   ```

3. **Start the server:**
   ```bash
   # On Windows
   start.bat
   
   # OR manually:
   uvicorn main:app --reload --host 0.0.0.0 --port 8000
   ```

4. **Verify the server is running:**
   - You should see: `Uvicorn running on http://0.0.0.0:8000`
   - Open browser: http://localhost:8000
   - You should see: `{"message": "Welcome to NoteFlow API"}`

### Solution 2: Check Windows Firewall

The backend is running on port 8000, but Windows Firewall might be blocking it.

**Option A: Allow Python through Firewall (Recommended)**

1. Open **Windows Defender Firewall**
2. Click **Allow an app or feature through Windows Defender Firewall**
3. Click **Change settings** (requires admin)
4. Find **Python** in the list
5. Check both **Private** and **Public** boxes
6. Click **OK**

**Option B: Create Firewall Rule for Port 8000**

Run this in **Administrator Command Prompt**:
```cmd
netsh advfirewall firewall add rule name="NoteFlow Backend" dir=in action=allow protocol=TCP localport=8000
```

### Solution 3: Verify Network Connection

1. **Check if your phone and PC are on the same WiFi network**
   - Phone WiFi: Settings → WiFi → Check network name
   - PC WiFi: Settings → Network & Internet → WiFi → Check network name
   - They MUST be the same network

2. **Find your PC's IP address:**
   ```cmd
   ipconfig
   ```
   Look for "IPv4 Address" under your WiFi adapter (e.g., 192.168.0.16)

3. **Test connection from phone:**
   - Open browser on phone
   - Go to: `http://192.168.0.16:8000`
   - You should see: `{"message": "Welcome to NoteFlow API"}`

### Solution 4: Update IP Address in App (If Changed)

If your PC's IP address changed:

1. **Find current IP:**
   ```cmd
   ipconfig
   ```

2. **Update in Flutter app:**
   Edit `lib/core/services/api_service.dart`:
   ```dart
   if (Platform.isAndroid) {
     return 'http://YOUR_NEW_IP:8000';  // Change this
   }
   ```

3. **Rebuild the app:**
   ```bash
   flutter run
   ```

### Solution 5: Use USB Debugging (Alternative)

If WiFi doesn't work, use USB with ADB reverse:

1. **Connect phone via USB**
2. **Enable USB debugging on phone**
3. **Run these commands:**
   ```bash
   adb reverse tcp:8000 tcp:8000
   ```

4. **Update API service to use localhost:**
   Edit `lib/core/services/api_service.dart`:
   ```dart
   if (Platform.isAndroid) {
     return 'http://localhost:8000';  // Use localhost with adb reverse
   }
   ```

5. **Rebuild and run:**
   ```bash
   flutter run
   ```

## Quick Test Commands

### Test 1: Is backend running?
```bash
curl http://localhost:8000
```
Expected: `{"message":"Welcome to NoteFlow API"}`

### Test 2: Can phone reach PC?
From phone browser: `http://192.168.0.16:8000`
Expected: `{"message":"Welcome to NoteFlow API"}`

### Test 3: Is port 8000 listening?
```cmd
netstat -an | findstr :8000
```
Expected: `TCP    0.0.0.0:8000    0.0.0.0:0    LISTENING`

## Most Common Issues

1. ❌ **Backend not running** → Start with `start.bat`
2. ❌ **Firewall blocking** → Allow Python or port 8000
3. ❌ **Different WiFi networks** → Connect both to same network
4. ❌ **IP address changed** → Update in api_service.dart
5. ❌ **MongoDB not running** → Backend will start but uploads fail

## Verify Everything Works

1. ✅ Backend running: http://localhost:8000
2. ✅ MongoDB connected: Check backend logs
3. ✅ Phone can reach backend: http://192.168.0.16:8000 in phone browser
4. ✅ Firewall allows connection
5. ✅ Same WiFi network

## Still Not Working?

Check backend logs for errors:
- Look at the terminal where you ran `start.bat`
- Check for MongoDB connection errors
- Check for port already in use errors

## Need More Help?

Share:
1. Backend terminal output
2. Result of `ipconfig` command
3. Result of `netstat -an | findstr :8000`
4. Phone browser test result
