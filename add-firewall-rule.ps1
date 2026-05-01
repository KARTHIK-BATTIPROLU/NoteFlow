# NoteFlow Backend - Windows Firewall Rule Setup
# This script adds a firewall rule to allow incoming connections on port 8000

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "NoteFlow Backend - Firewall Setup" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Check if running as Administrator
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $isAdmin) {
    Write-Host "ERROR: This script must be run as Administrator!" -ForegroundColor Red
    Write-Host ""
    Write-Host "To run as Administrator:" -ForegroundColor Yellow
    Write-Host "1. Right-click on PowerShell" -ForegroundColor Yellow
    Write-Host "2. Select 'Run as Administrator'" -ForegroundColor Yellow
    Write-Host "3. Navigate to this directory and run the script again" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Or run this command in an Administrator PowerShell:" -ForegroundColor Yellow
    Write-Host "New-NetFirewallRule -DisplayName 'NoteFlow Backend' -Direction Inbound -LocalPort 8000 -Protocol TCP -Action Allow" -ForegroundColor Green
    Write-Host ""
    pause
    exit 1
}

Write-Host "✓ Running as Administrator" -ForegroundColor Green
Write-Host ""

# Check if rule already exists
$existingRule = Get-NetFirewallRule -DisplayName "NoteFlow Backend" -ErrorAction SilentlyContinue

if ($existingRule) {
    Write-Host "⚠ Firewall rule 'NoteFlow Backend' already exists!" -ForegroundColor Yellow
    Write-Host ""
    $response = Read-Host "Do you want to remove and recreate it? (y/n)"
    
    if ($response -eq 'y' -or $response -eq 'Y') {
        Write-Host "Removing existing rule..." -ForegroundColor Yellow
        Remove-NetFirewallRule -DisplayName "NoteFlow Backend"
        Write-Host "✓ Existing rule removed" -ForegroundColor Green
        Write-Host ""
    } else {
        Write-Host "Keeping existing rule. Exiting..." -ForegroundColor Yellow
        pause
        exit 0
    }
}

# Create the firewall rule
Write-Host "Creating firewall rule for port 8000..." -ForegroundColor Cyan

try {
    New-NetFirewallRule `
        -DisplayName "NoteFlow Backend" `
        -Description "Allows incoming connections to NoteFlow FastAPI backend on port 8000" `
        -Direction Inbound `
        -LocalPort 8000 `
        -Protocol TCP `
        -Action Allow `
        -Profile Any `
        -Enabled True
    
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Green
    Write-Host "✓ SUCCESS!" -ForegroundColor Green
    Write-Host "========================================" -ForegroundColor Green
    Write-Host ""
    Write-Host "Firewall rule created successfully!" -ForegroundColor Green
    Write-Host ""
    Write-Host "Rule Details:" -ForegroundColor Cyan
    Write-Host "  Name: NoteFlow Backend" -ForegroundColor White
    Write-Host "  Port: 8000" -ForegroundColor White
    Write-Host "  Protocol: TCP" -ForegroundColor White
    Write-Host "  Direction: Inbound" -ForegroundColor White
    Write-Host "  Action: Allow" -ForegroundColor White
    Write-Host "  Status: Enabled" -ForegroundColor White
    Write-Host ""
    
    # Get computer's IP address
    Write-Host "Your Computer's IP Addresses:" -ForegroundColor Cyan
    Get-NetIPAddress -AddressFamily IPv4 | Where-Object { $_.IPAddress -notlike "127.*" -and $_.IPAddress -notlike "169.*" } | ForEach-Object {
        Write-Host "  $($_.IPAddress)" -ForegroundColor White
    }
    Write-Host ""
    
    Write-Host "Next Steps:" -ForegroundColor Yellow
    Write-Host "1. Ensure backend is running (should already be running)" -ForegroundColor White
    Write-Host "2. Test from Android device browser: http://192.168.0.16:8000/" -ForegroundColor White
    Write-Host "3. Try uploading a file from your Flutter app" -ForegroundColor White
    Write-Host ""
    
    Write-Host "To verify the rule was created:" -ForegroundColor Cyan
    Write-Host "  Get-NetFirewallRule -DisplayName 'NoteFlow Backend' | Format-List" -ForegroundColor Gray
    Write-Host ""
    
    Write-Host "To remove the rule later:" -ForegroundColor Cyan
    Write-Host "  Remove-NetFirewallRule -DisplayName 'NoteFlow Backend'" -ForegroundColor Gray
    Write-Host ""
    
} catch {
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Red
    Write-Host "✗ ERROR!" -ForegroundColor Red
    Write-Host "========================================" -ForegroundColor Red
    Write-Host ""
    Write-Host "Failed to create firewall rule:" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    Write-Host ""
    Write-Host "Please try manually:" -ForegroundColor Yellow
    Write-Host "1. Press Win + R, type 'wf.msc', press Enter" -ForegroundColor White
    Write-Host "2. Click 'Inbound Rules' → 'New Rule...'" -ForegroundColor White
    Write-Host "3. Port → TCP → 8000 → Allow → All profiles" -ForegroundColor White
    Write-Host "4. Name: 'NoteFlow Backend'" -ForegroundColor White
    Write-Host ""
    pause
    exit 1
}

pause
