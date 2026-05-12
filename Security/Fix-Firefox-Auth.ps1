# Description: Adds Windows/Kerberos authentication preferences to Firefox's user prefs file,
#              enabling seamless NTLM/Negotiate auth for trusted internal sites.
# Requirements: Run as the user whose Firefox profile should be updated
param(
    [string]$TrustedDomain = 'domain.local'   # Internal domain to trust for automatic authentication
)

$PrefLines = @(
    "user_pref(`"network.automatic-ntlm-auth.trusted-uris`", `"$TrustedDomain`");",
    "user_pref(`"network.negotiate-auth.delegation-uris`", `"$TrustedDomain`");",
    "user_pref(`"network.negotiate-auth.trusted-uris`", `"$TrustedDomain`");",
    "user_pref(`"signon.autologin.proxy`", true);"
)

$ProfilesPath = Join-Path $env:APPDATA 'Mozilla\Firefox\Profiles'

if (-not (Test-Path $ProfilesPath)) { Write-Warning 'Firefox profiles folder not found.'; return }

$Profiles = Get-ChildItem $ProfilesPath -Directory
foreach ($Profile in $Profiles) {
    $PrefsFile = Join-Path $Profile.FullName 'prefs.js'
    if (Test-Path $PrefsFile) {
        $PrefLines | Add-Content $PrefsFile
        Write-Host "Updated: $PrefsFile" -ForegroundColor Green
    }
}
