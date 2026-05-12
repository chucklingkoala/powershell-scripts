# Description: Batch renames files in a folder by extracting a date substring from the original filename
#              and prepending it in YYYYMMDD format, with a configurable suffix.
# Pattern: Extract date from filename position → reformat → rename
param(
    [string]$Path         = 'C:\Scripts\Backup',
    [string]$NewSuffix    = 'Report',          # Suffix appended after the reformatted date
    [string]$Extension    = '.pdf',
    [int]$DateStartIndex  = 3,                 # Character position after " - " where the date starts
    [string]$Separator    = ' - '              # Separator used to locate the date in the filename
)

$Files = Get-ChildItem $Path -File -Filter "*$Extension"
foreach ($File in $Files) {
    $SepIdx     = $File.Name.IndexOf($Separator)
    if ($SepIdx -lt 0) { Write-Warning "Skipping $($File.Name) — separator not found"; continue }
    $DateStr    = $File.Name.Substring($SepIdx + $Separator.Length, 10)
    $NewDate    = Get-Date $DateStr -UFormat '%Y%m%d'
    $NewName    = Join-Path $File.DirectoryName "$NewDate - $NewSuffix$Extension"
    Move-Item $File.FullName $NewName
    Write-Host "Renamed: $($File.Name) → $(Split-Path $NewName -Leaf)"
}
