# Description: Generates HTML reports showing file count and size for each subfolder, sorted three ways
# Requirements: Read access to the target path
param(
    [string]$Path       = 'C:\Data',
    [string]$OutputPath = 'C:\Data'   # HTML files are written here
)

$DataTable = New-Object System.Data.DataTable
$DataTable.Columns.Add((New-Object System.Data.DataColumn 'Folder',    ([string])))
$DataTable.Columns.Add((New-Object System.Data.DataColumn 'FileCount', ([int32])))
$DataTable.Columns.Add((New-Object System.Data.DataColumn 'SizeGB',    ([double])))

foreach ($Folder in (Get-ChildItem $Path -Directory)) {
    $Row            = $DataTable.NewRow()
    $Row.Folder     = $Folder.Name
    $Row.FileCount  = $Folder.GetFiles().Count
    $SizeBytes      = ($Folder.GetFiles() | Measure-Object -Property Length -Sum).Sum
    $Row.SizeGB     = [Math]::Round($SizeBytes / 1GB, 3)
    $DataTable.Rows.Add($Row)
}

function Write-HTMLReport {
    param([string]$Title, [object[]]$Rows, [string]$OutFile)
    $Table = '<style>table,th,td{border:1px solid black;border-collapse:collapse;}</style><table><tr><td>Folder</td><td>File Count</td><td>Size (GB)</td></tr>'
    foreach ($Row in $Rows) {
        $Table += "<tr><td>$($Row.Folder)</td><td align=right>$($Row.FileCount)</td><td align=right>$($Row.SizeGB)</td></tr>"
    }
    $Table += '</table>'
    "<HTML><Body><H1>$Title</H1>$Table</Body></HTML>" | Out-File $OutFile
    Write-Host "Written: $OutFile"
}

Write-HTMLReport 'Folder Report — Alphabetical'   ($DataTable | Sort-Object Folder)                           (Join-Path $OutputPath 'Report-Alphabetical.html')
Write-HTMLReport 'Folder Report — By File Count'  ($DataTable | Sort-Object FileCount -Descending)           (Join-Path $OutputPath 'Report-ByCount.html')
Write-HTMLReport 'Folder Report — By Size'        ($DataTable | Sort-Object SizeGB    -Descending)           (Join-Path $OutputPath 'Report-BySize.html')
