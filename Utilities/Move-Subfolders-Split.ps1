# Description: Moves files from a source folder into subfolders named after the portion of the
#              filename before the first occurrence of a split character (e.g. '-')
param(
    [string]$SourceDir      = 'C:\Unsorted',
    [string]$DestinationDir = 'C:\Sorted',
    [string]$SplitChar      = '-'
)

$Files = Get-ChildItem -Path $SourceDir -File

foreach ($File in $Files) {
    $FolderName = $File.Name.Split($SplitChar, 2)[0].Trim()
    $DestFolder = Join-Path $DestinationDir $FolderName
    if (-not (Test-Path $DestFolder)) { New-Item $DestFolder -ItemType Directory | Out-Null }
    $DestFile = Join-Path $DestFolder $File.Name
    Copy-Item -Path $File.FullName -Destination $DestFile
    Write-Host "Moved: $($File.Name) → $FolderName"
}
