# Run this script as Administrator to allow your phone to reach the backend server
# Right-click this file → "Run with PowerShell" (as Administrator)

Write-Host "Adding Windows Firewall rule to allow port 3000..." -ForegroundColor Cyan

netsh advfirewall firewall add rule name="Flutter Dev - Allow Port 3000" dir=in action=allow protocol=TCP localport=3000

if ($LASTEXITCODE -eq 0) {
    Write-Host ""
    Write-Host "SUCCESS! Port 3000 is now open for incoming connections." -ForegroundColor Green
    Write-Host "Your phone should be able to reach the server now." -ForegroundColor Green
} else {
    Write-Host ""
    Write-Host "FAILED - Make sure you are running this as Administrator!" -ForegroundColor Red
}

Write-Host ""
Write-Host "Press any key to close..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
