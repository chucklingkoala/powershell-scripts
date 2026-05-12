# Description: Enables and enforces OneDrive Known Folder Move (KFM) via registry policy.
#              Silently moves Desktop, Documents, and Pictures to OneDrive without user prompt.
# Requirements: Run as SYSTEM or local admin (HKLM writes), typically deployed via Intune or GPO
# Note: KFMSilentOptIn value must be set to your Azure AD / Entra tenant ID (GUID).
param(
    [Parameter(Mandatory)][string]$TenantID   # Your Entra/Azure AD tenant ID (GUID)
)

$PolicyPath = 'HKLM:\SOFTWARE\Policies\Microsoft\OneDrive'

function Set-RegValue {
    param([string]$Path, [string]$Name, $Value, [string]$Type)
    if (-not (Test-Path $Path)) { New-Item -Path $Path -Force | Out-Null }
    New-ItemProperty -Path $Path -Name $Name -Value $Value -PropertyType $Type -Force | Out-Null
}

# Block users from opting in to KFM themselves (enforce via policy only)
Set-RegValue $PolicyPath 'KFMBlockOptIn'                  1          DWORD

# Silently move known folders to OneDrive using the tenant ID
Set-RegValue $PolicyPath 'KFMSilentOptIn'                 $TenantID  String

# Do not show notification after silent KFM completes
Set-RegValue $PolicyPath 'KFMSilentOptInWithNotification' 0          DWORD

# Prevent users from redirecting folders back out of OneDrive
Set-RegValue $PolicyPath 'KFMBlockOptOut'                 1          DWORD

Write-Host "OneDrive KFM policy applied for tenant: $TenantID"
