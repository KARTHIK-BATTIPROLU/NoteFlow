# Upload Fix - Complete ✅

## Problem Identified
The app couldn't upload files because:
1. ❌ Backend server was NOT running
2. ❌ IP address in app (192.168.0.16) didn't match PC's actual IP (10.161.157.42)

## Fixes Applied

### 1. ✅ Backend Server Started
- Started FastAPI server on port 8000
- Server is running at: `http://0.0.0.0:8000`
- MongoDB connected successfully
- Verified with test: `{"message":"Welcome to NoteFlow API"}`

### 2. ✅ IP Address Updated
- Changed from: `http://192.168.0.16:8000`
- Changed to: `http://10.161.157.42:8000`
- Updated in: `lib/core/services/api_service.dart`

## Next Steps

### Step 1: Add Firewall Rule (Important!)
Windows Firewall might still block connections from your phone.

**Run as Administrator:**
```
ADD_FIREWALL_RULE.bat
```

Or manually:
1. Open Windows Defender Firewall
2. Click "Advanced settings"
3. Click "Inbound Rules" → "New Rule"
4. Select "Port" → Next
5. Select "TCP" and enter "8000" → Next
6. Select "Allow the connection" → Next
7. Check all profiles → Next
8. Name it "NoteFlow Backend" → Finish

### Step 2: Rebuild and Run the App
```bash
flutter run
```

The app will now use the correct IP address (10.161.157.42).

### Step 3: Test Upload
1. Open the app on your phone
2. Go to Upload tab
3. Select a PDF file
4. Fill in title, subject, and topic
5. Click Upload
6. Should work now! ✅

## Verify Everything

### Backend Status
- ✅ Server running: http://localhost:8000
- ✅ MongoDB connected
- ✅ Port 8000 listening

### Network Configuration
- PC IP: 10.161.157.42
- App configured: http://10.161.157.42:8000
- Port: 8000

### Test from Phone Browser
Before testing upload in app, verify connection:
1. Open browser on your phone
2. Go to: `http://10.161.157.42:8000`
3. Should see: `{"message":"Welcome to NoteFlow API"}`

If you see the message, upload will work!

## Troubleshooting

### If still can't connect:

**1. Check Firewall**
```cmd
netsh advfirewall firewall show rule name="NoteFlow Backend Port 8000"
```

**2. Check if backend is running**
```cmd
netstat -an | findstr :8000
```
Should show: `TCP    0.0.0.0:8000    LISTENING`

**3. Check if phone and PC are on same network**
- Phone: Settings → WiFi → Check network name
- PC: Settings → Network & Internet → WiFi → Check network name
- Must be the same!

**4. Test from PC browser**
Open: http://10.161.157.42:8000
Should see: `{"message":"Welcome to NoteFlow API"}`

**5. Test from phone browser**
Open: http://10.161.157.42:8000
Should see: `{"message":"Welcome to NoteFlow API"}`

### If IP address changes again:

Your IP might change if you:
- Restart your PC
- Disconnect/reconnect WiFi
- Switch networks

To find new IP:
```cmd
ipconfig
```
Look for "IPv4 Address" and update in `lib/core/services/api_service.dart`

## Backend Server Management

### Keep Backend Running
The backend server is now running in the background. Keep it running while using the app.

### Stop Backend Server
If you need to stop it:
```cmd
# Find the process
netstat -ano | findstr :8000

# Kill the process (replace PID with actual number)
taskkill /PID <PID> /F
```

### Restart Backend Server
```cmd
cd backend
uvicorn main:app --reload --host 0.0.0.0 --port 8000
```

## Summary

✅ Backend server is running
✅ IP address updated in app
✅ MongoDB connected
✅ Ready to test upload

**Next:** 
1. Run `ADD_FIREWALL_RULE.bat` as Administrator
2. Rebuild app: `flutter run`
3. Test upload from phone

The upload should work now! 🎉
