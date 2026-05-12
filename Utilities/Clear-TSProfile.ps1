# Description: Clears the Terminal Services profile path for a list of usernames from a text file
# Requirements: Quest ActiveRoles AD Management snapin (or adapt to use Set-ADUser)
param(
    [Parameter(Mandatory)][string]$UserListFile   # Text file with one username per line
)

Get-Content $UserListFile | ForEach-Object {
    $Username = [string]$_
    Set-QADUser $Username -TSProfilePath ''
    Write-Host "Cleared TS profile path for: $Username"
}

# Native AD equivalent (uncomment if not using Quest):
# Get-Content $UserListFile | ForEach-Object {
#     Set-ADUser $_ -Clear 'profilePath'
# }
