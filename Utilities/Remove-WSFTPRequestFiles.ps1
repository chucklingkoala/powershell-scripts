# Description: Removes WS_FTP Pro request_*.dat temporary files left in the user's AppData profile.
#              These accumulate over time and can cause WS_FTP to misbehave.
# Requirements: Run as the service account or user that runs WS_FTP
param(
    [string]$ServiceAccount = 'service-ftp',    # Username whose AppData to clean
    [string]$BasePath       = 'C:\Users'        # Base path for user profiles
)

$WSFTPAppData = Join-Path $BasePath "$ServiceAccount\AppData\Roaming\Ipswitch\WS_FTP"
$RequestFiles = Get-ChildItem $WSFTPAppData -Filter 'request_*.dat' -File -Recurse -ErrorAction SilentlyContinue

if ($RequestFiles) {
    $RequestFiles | Remove-Item -Force
    Write-Host "Removed $($RequestFiles.Count) WS_FTP request file(s)." -ForegroundColor Green
} else {
    Write-Host 'No WS_FTP request files found.'
}
