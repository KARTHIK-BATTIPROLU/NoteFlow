# MongoDB Upload Connection Timeout Fix

## Problem Identified

Your Flutter app is experiencing connection timeouts when uploading files to MongoDB because:

1. **Backend server is running** on `http://0.0.0.0:8000` (listening on all interfaces)
2. **Flutter app is trying to connect** to `http://192.168.0.16:8000`
3. **Connection is being blocked** - likely by Windows Firewall or network configuration

## Root Cause

The error message shows:
```
SocketException: Connection timed out (OS Error: Connection timed out, errno = 110), 
address = 192.168.0.16, port = 37442
```

This indicates the Android device cannot reach your computer's IP address on port 8000.

## Solutions

### Solution 1: Configure Windows Firewall (RECOMMENDED)

Allow incoming connections on port 8000:

1. **Open Windows Defender Firewall with Advanced Security**
   - Press `Win + R`, type `wf.msc`, press Enter

2. **Create Inbound Rule**
   - Click "Inbound Rules" in left panel
   - Click "New Rule..." in right panel
   - Select "Port" → Next
   - Select "TCP" and enter "8000" → Next
   - Select "Allow the connection" → Next
   - Check all profiles (Domain, Private, Public) → Next
   - Name: "NoteFlow Backend" → Finish

3. **Verify the rule is enabled**
   - Find "NoteFlow Backend" in the list
   - Ensure it shows "Enabled" in the status

### Solution 2: Quick Test with Firewall Temporarily Disabled

**⚠️ WARNING: Only for testing, not recommended for production**

1. Open Windows Defender Firewall
2. Click "Turn Windows Defender Firewall on or off"
3. Temporarily turn off for Private networks
4. Test the upload
5. **IMPORTANT: Turn firewall back on immediately after testing**

### Solution 3: Use USB Debugging with Port Forwarding

If firewall configuration doesn't work:

1. Connect your Android device via USB
2. Enable USB debugging on your device
3. Run this command:
   ```bash
   adb reverse tcp:8000 tcp:8000
   ```
4. Update Flutter app to use `http://localhost:8000` instead of `http://192.168.0.16:8000`

### Solution 4: Update API Service to Use Localhost (for USB debugging)

If using USB debugging, modify `lib/core/services/api_service.dart`:

```dart
static String getBaseUrl() {
  try {
    if (Platform.isAndroid) {
      // When using USB debugging with adb reverse
      return 'http://localhost:8000';
      // OR for emulator:
      // return 'http://10.0.2.2:8000';
    }
  } catch (_) {}
  return 'http://localhost:8000';
}
```

## Verification Steps

After applying Solution 1 (Firewall rule):

1. **Test from your computer:**
   ```powershell
   Invoke-WebRequest -Uri http://192.168.0.16:8000/ -TimeoutSec 5
   ```
   Should return: `{"message":"Welcome to NoteFlow API"}`

2. **Test from Android device:**
   - Open browser on your Android device
   - Navigate to `http://192.168.0.16:8000/`
   - Should see: `{"message":"Welcome to NoteFlow API"}`

3. **Test file upload:**
   - Try uploading a file from your Flutter app
   - Check backend logs for upload progress

## Backend Server Status

✅ Backend is currently running on `http://0.0.0.0:8000`
✅ Accessible on localhost: `http://localhost:8000`
❌ Not accessible on network: `http://192.168.0.16:8000` (firewall blocking)

## Additional Troubleshooting

### Check if port 8000 is listening on all interfaces:

```powershell
netstat -ano | findstr :8000
```

Should show something like:
```
TCP    0.0.0.0:8000           0.0.0.0:0              LISTENING       [PID]
```

### Check your computer's IP address:

```powershell
ipconfig
```

Look for "IPv4 Address" under your active network adapter.

### Test backend connectivity from Android:

1. Install a network testing app (like "Network Analyzer")
2. Try to ping `192.168.0.16`
3. Try to connect to port `8000`

## Backend Configuration

The backend is correctly configured to listen on all interfaces:
```python
# In backend/start.bat
uvicorn main:app --reload --host 0.0.0.0 --port 8000
```

The `--host 0.0.0.0` means it accepts connections from any network interface.

## Next Steps

1. **Apply Solution 1** (Windows Firewall rule) - This is the most reliable solution
2. **Verify** the backend is accessible from your Android device
3. **Test upload** with a small file first
4. **Monitor backend logs** for any errors

## Backend Logs Location

The backend server is running in terminal ID: 12
You can view logs in the terminal or check for errors in the FastAPI output.

## File Upload Limits

Current backend configuration:
- **Max file size:** 50 MB
- **Supported formats:** PDF, PPT, PPTX
- **Storage:** MongoDB GridFS (chunked storage for large files)

## Common Issues

### Issue: "Connection refused"
- Backend is not running
- Wrong IP address
- Wrong port number

### Issue: "Connection timeout"
- Firewall blocking connection ✅ **YOUR CURRENT ISSUE**
- Network not reachable
- Backend crashed

### Issue: "413 Payload Too Large"
- File exceeds 50 MB limit
- Increase `MAX_FILE_SIZE` in `backend/main.py`

### Issue: "401 Unauthorized"
- Firebase token expired
- Invalid Firebase token
- Firebase Admin not configured

## Support

If issues persist after applying the firewall rule:
1. Check backend logs for errors
2. Verify MongoDB connection
3. Test with a smaller file (< 1 MB)
4. Check network connectivity between devices
