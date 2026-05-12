# Description: Enables OneDrive silent account configuration and Files On Demand via registry policy
# Requirements: Run as SYSTEM or local admin (HKLM writes), typically deployed via Intune or GPO
$PolicyPath = 'HKLM:\SOFTWARE\Policies\Microsoft\OneDrive'

function Set-RegValue {
    param([string]$Path, [string]$Name, $Value, [string]$Type)
    if (-not (Test-Path $Path)) { New-Item -Path $Path -Force | Out-Null }
    New-ItemProperty -Path $Path -Name $Name -Value $Value -PropertyType $Type -Force | Out-Null
}

# Sign in users automatically using their Windows credentials
Set-RegValue $PolicyPath 'SilentAccountConfig'  1 DWORD

# Enable Files On Demand (placeholder files instead of full sync)
Set-RegValue $PolicyPath 'FilesOnDemandEnabled' 1 DWORD

Write-Host 'OneDrive silent account config and Files On Demand enabled.'
