# Description: Creates a ZIP archive for each subfolder in the current directory
# Requirements: PowerShell 5+ (Compress-Archive)
# Run from the parent folder containing the subfolders to compress
$FolderList = Get-ChildItem -Directory
foreach ($Folder in $FolderList) {
    $ZipPath = "$($Folder.Name).zip"
    Compress-Archive -LiteralPath $Folder.FullName -DestinationPath $ZipPath
    Write-Host "Created: $ZipPath"
}
