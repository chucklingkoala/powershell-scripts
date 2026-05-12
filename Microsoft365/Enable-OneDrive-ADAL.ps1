# Description: Enables Modern Authentication (ADAL) for OneDrive via registry (per-user setting)
# Requirements: Run in user context or deploy via Intune per-user script
$RegistryPath = 'HKCU:\SOFTWARE\Microsoft\OneDrive'
if (-not (Test-Path $RegistryPath)) { New-Item -Path $RegistryPath -Force | Out-Null }
New-ItemProperty -Path $RegistryPath -Name 'EnableADAL' -Value 1 -PropertyType DWORD -Force | Out-Null
Write-Host 'OneDrive ADAL (Modern Authentication) enabled.'
