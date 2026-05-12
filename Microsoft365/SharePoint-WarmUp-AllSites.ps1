# Description: Warms up all SharePoint site collections across all web applications using default
#              credentials. Also warms up extra URLs listed in an external text file (e.g. OWA, SSRS).
# Requirements: SharePoint Management Shell (on-premises SharePoint 2013/2016/2019)
param(
    [string]$ExtraSitesFile = 'C:\Scripts\warmup-extrasites.txt'   # One URL per line
)

Add-PSSnapin Microsoft.SharePoint.PowerShell -ErrorAction SilentlyContinue

Start-SPAssignment -Global

foreach ($App in (Get-SPWebApplication -IncludeCentralAdministration)) {
    foreach ($Site in (Get-SPSite -WebApplication $App.Url -Limit ALL)) {
        Write-Host $Site.Url
        $r = Invoke-WebRequest -URI $Site.Url -UseDefaultCredentials
        Write-Host "  HTTP $($r.StatusCode)"
    }
}

if (Test-Path $ExtraSitesFile) {
    foreach ($Url in (Get-Content $ExtraSitesFile)) {
        Write-Host "Warming extra site: $Url"
        Invoke-WebRequest -Uri $Url -UseDefaultCredentials | Out-Null
    }
}

Stop-SPAssignment -Global
