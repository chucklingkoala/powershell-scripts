# Description: Moves loose files in a folder into subfolders named after the leading part of each
#              filename (split on a delimiter character). Creates the folder if it doesn't exist.
param(
    [string]$Root      = 'D:\Unsorted\',    # Must have trailing backslash
    [string]$Delimiter = '-'               # Character used to extract the folder name from the filename
)

$FileList = Get-ChildItem $Root -File

foreach ($File in $FileList) {
    $SplitChar = $Delimiter
    if ($File.Name -like '*&*') { $SplitChar = '&' }

    $FolderName = ($File.Name.Split($SplitChar)[0]).TrimEnd()
    $DestFolder = Join-Path $Root $FolderName

    if (-not (Test-Path $DestFolder)) { New-Item $DestFolder -ItemType Directory | Out-Null }
    Move-Item $File.FullName $DestFolder
}
