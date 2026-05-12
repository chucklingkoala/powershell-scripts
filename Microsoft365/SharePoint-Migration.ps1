# Description: Migrates SharePoint users from Windows authentication to ADFS claims-based authentication
# Requirements: SharePoint Management Shell (SharePoint on-premises)
param(
    [string]$SiteURL         = 'https://sharepoint.domain.local',
    [string]$WinAuthDomain   = 'DOMAIN',
    [string]$ADFSProvider    = 'adfs provider',   # ADFS trust display name in SharePoint
    [string]$ADFSDomain      = 'domain.local'
)

Add-PSSnapin Microsoft.SharePoint.PowerShell -ErrorAction SilentlyContinue

$WinAuthPrefix  = "i:0#.w|$WinAuthDomain\"
$ADFSAuthPrefix = "i:05.t|$ADFSProvider|"
$ADFSAuthPostfix = "@$ADFSDomain"

$SPUsers = Get-SPUser -Web $SiteURL | Where-Object { $_.UserLogin -like ($WinAuthPrefix + '*') }

foreach ($User in $SPUsers) {
    if ($User.DisplayName -notlike 'Service*') {
        $SamAccount = $User.UserLogin.Substring($User.UserLogin.LastIndexOf('\') + 1)
        $NewAlias   = $ADFSAuthPrefix + $SamAccount + $ADFSAuthPostfix
        Move-SPUser -Identity $User -NewAlias $NewAlias -IgnoreSID
    }
}
