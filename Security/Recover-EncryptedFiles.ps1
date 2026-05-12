# Description: Recovers files that were encrypted by ransomware (left with .Encrypted extension)
#              by copying clean versions from a backup/recovery path to the original locations.
# Requirements: Access to both the encrypted path and the backup/recovery path
param(
    [string]$EncryptedPath = 'C:\Recovery\Encrypted',  # Folder containing .Encrypted files
    [string]$BackupPath    = 'C:\Recovery\Backup',      # Backup source with clean copies
    [string]$Extension     = '.encrypted'               # Extension to look for (case-insensitive)
)

$EncryptedFiles = Get-ChildItem $EncryptedPath -Recurse -Filter "*$Extension"

foreach ($File in $EncryptedFiles) {
    $OriginalName = $File.FullName.Substring(0, $File.FullName.ToLower().IndexOf($Extension.ToLower()))
    $RelativePath = $OriginalName.Substring($EncryptedPath.Length)
    $RestorePath  = Join-Path $BackupPath $RelativePath

    if (Test-Path $RestorePath) {
        Copy-Item $RestorePath $OriginalName -Force
        Write-Host "Restored: $OriginalName" -ForegroundColor Green
    } else {
        Write-Warning "Backup not found for: $OriginalName"
    }
}
