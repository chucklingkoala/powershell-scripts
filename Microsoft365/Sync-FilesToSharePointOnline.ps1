# Description: Syncs files modified in the last 24 hours from a local folder to a SharePoint Online document library using CSOM
# Requirements: SharePoint Client Components SDK (Microsoft.SharePoint.Client.dll)
#   Download: https://www.microsoft.com/en-us/download/details.aspx?id=42038
param(
    [Parameter(Mandatory)][string]$SiteURL,
    [Parameter(Mandatory)][string]$DocLibName,
    [string]$SourceFolder = 'C:\SyncSource',
    [PSCredential]$Credential = (Get-Credential -Message 'Enter SharePoint Online credentials'),
    [string]$CSOMPath = 'C:\Program Files\Common Files\Microsoft Shared\Web Server Extensions\16\ISAPI'
)

Add-Type -Path "$CSOMPath\Microsoft.SharePoint.Client.dll"
Add-Type -Path "$CSOMPath\Microsoft.SharePoint.Client.Runtime.dll"

$Context = New-Object Microsoft.SharePoint.Client.ClientContext($SiteURL)
$Context.Credentials = New-Object Microsoft.SharePoint.Client.SharePointOnlineCredentials(
    $Credential.UserName,
    $Credential.Password
)

$List = $Context.Web.Lists.GetByTitle($DocLibName)
$Context.Load($List)
$Context.ExecuteQuery()

$Cutoff = (Get-Date).AddDays(-1)

foreach ($File in (Get-ChildItem $SourceFolder -File | Where-Object { $_.LastWriteTime -gt $Cutoff })) {
    $Stream          = New-Object System.IO.FileStream($File.FullName, [System.IO.FileMode]::Open)
    $FileInfo        = New-Object Microsoft.SharePoint.Client.FileCreationInformation
    $FileInfo.Overwrite      = $false
    $FileInfo.ContentStream  = $Stream
    $FileInfo.URL            = $File.Name

    $Upload = $List.RootFolder.Files.Add($FileInfo)
    $Context.Load($Upload)
    $Context.ExecuteQuery()
    $Stream.Close()

    Write-Host "Uploaded: $($File.Name)"
}
