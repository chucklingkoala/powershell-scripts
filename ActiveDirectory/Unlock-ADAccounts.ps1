# Description: Unlocks all locked AD accounts matching a name pattern
# Requirements: Quest ActiveRoles AD Management snapin
# Note: Replace Get-QADUser/Unlock-QADUser with native AD equivalents if Quest is not installed:
#   Get-ADUser -Filter {LockedOut -eq $true} | Unlock-ADAccount
param(
    [string]$AccountPattern = 'admin-*'   # Filter pattern to match account names
)

# Quest AD version:
Get-QADUser -Locked $AccountPattern | ForEach-Object { Unlock-QADUser $_.LogonName }

# Native AD version (uncomment if using ActiveDirectory module instead of Quest):
# Get-ADUser -Filter { SamAccountName -like $AccountPattern -and LockedOut -eq $true } | Unlock-ADAccount
