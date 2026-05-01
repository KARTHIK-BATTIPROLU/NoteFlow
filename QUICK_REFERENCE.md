# Quick Reference Card

## ✅ Current Status
- Backend: **RUNNING** on localhost:8000
- Phone: **CONNECTED** via USB
- ADB Reverse: **ACTIVE** (port 8000)
- App: **RUNNING** on phone
- Configuration: **localhost:8000**

## 🎯 Test Upload Now!
1. Open app on phone
2. Go to Upload tab
3. Select PDF
4. Fill details
5. Click Upload
6. **Should work!** ✅

## 🔧 If Something Goes Wrong

### Upload Fails?
```bash
# Re-setup ADB reverse
adb reverse tcp:8000 tcp:8000

# Hot restart app (in Flutter terminal)
Press 'R'
```

### Backend Not Responding?
```bash
# Check backend
curl http://localhost:8000

# If not running, restart
cd backend
start.bat
```

### Phone Disconnected?
```bash
# Check connection
adb devices

# Re-setup ADB reverse
adb reverse tcp:8000 tcp:8000
```

## 📱 App Controls (Flutter Terminal)
- **R** = Hot restart (full restart)
- **r** = Hot reload (quick refresh)
- **q** = Quit app

## 🔍 Verify Everything

### 1. Backend Running?
```bash
curl http://localhost:8000
```
Expected: `{"message":"Welcome to NoteFlow API"}`

### 2. Phone Connected?
```bash
adb devices
```
Expected: Your device listed

### 3. ADB Reverse Active?
```bash
adb reverse --list
```
Expected: `tcp:8000 tcp:8000`

### 4. App Running?
Look at your phone - app should be open

## 📝 What Changed
- **Before:** WiFi connection to 192.168.0.16:8000 ❌
- **After:** USB connection to localhost:8000 ✅

## 🎉 Success Indicators
- Upload progress bar appears
- Backend logs show: `POST /upload`
- Success message appears
- File appears in Explore tab

## ⚠️ Remember
- Keep USB cable connected
- Keep backend running
- If you restart PC, run: `adb reverse tcp:8000 tcp:8000`

---

**Everything is ready! Test the upload now! 🚀**
