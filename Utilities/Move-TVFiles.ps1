# Description: Sorts TV episode files into per-series subfolders by detecting SxxExx episode codes
#              in filenames (e.g. S01E04). Run from the folder containing the episode files.
param(
    [string]$TVRoot = 'D:\TV\'  # Must have trailing backslash; contains both episode files and series folders
)

$ShowList = Get-ChildItem $TVRoot -Directory
$FileList = Get-ChildItem $TVRoot -File

foreach ($Episode in $FileList) {
    $EpNum    = $null
    $FileParts = $Episode.Name.Split('.')
    foreach ($Part in $FileParts) {
        if ($Part -match 'S\d{2}E\d{2}') { $EpNum = $Part; break }
    }
    if (-not $EpNum) { Write-Warning "No SxxExx found in: $($Episode.Name)"; continue }

    $ShowName   = $Episode.Name.Substring(0, $Episode.Name.IndexOf($EpNum) - 1)
    $SeriesName = $ShowName -replace '\.', ' '
    $SeriesPath = Join-Path $TVRoot $SeriesName

    if (Test-Path $SeriesPath) {
        Move-Item $Episode.FullName $SeriesPath
        Write-Host "Moved: $($Episode.Name) → $SeriesName"
    } else {
        Write-Warning "Series folder not found for: $SeriesName (create it first)"
    }
}
