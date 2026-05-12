# Description: Reports the size of each user home drive folder on a file share
# Requirements: Read access to the home drive share
param(
    [string]$UserDataPath = '\\fileserver\UserData'
)

$FolderArray = @()

foreach ($Folder in (Get-ChildItem -Directory $UserDataPath)) {
    $FolderSize = Get-ChildItem -Recurse $Folder.FullName | Measure-Object -Property Length -Sum
    $FolderArray += [PSCustomObject]@{
        FolderName = $Folder.Name
        FolderSize = $FolderSize.Sum
    }
    Write-Host "$($Folder.Name) : $($FolderSize.Sum) bytes"
}

$FolderArray | Sort-Object FolderSize -Descending | Format-Table -AutoSize
