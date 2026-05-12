# Description: Uploads files to a remote SFTP server using WinSCP, appending a protocol extension
#              before upload (.eml01 for PDF/XLS/CSV, .wmq01 for WMQ files). Verifies success by
#              parsing the WinSCP log; reverts rename on failure, moves to Sent folder on success.
# Requirements: WinSCP installed, pre-configured WinSCP session
# Pattern: Rename → build command file → WinSCP upload → log parse → revert or move to Sent
param(
    [string]$SourcePath      = '\\fileserver\share\OutboundFiles',
    [string]$SentPath        = '\\fileserver\share\OutboundFiles\Sent',
    [string]$WinSCPSession   = 'RemoteServer',    # Pre-configured session name in WinSCP
    [string]$RemoteDirectory = '/outbound',
    [string]$WinSCPExe       = 'C:\Program Files (x86)\WinSCP\WinSCP.com',
    [string]$ScriptWorkDir   = 'C:\Scripts\SFTPUpload',
    [string]$StandardExt     = '.eml01',   # Extension appended to standard files before upload
    [string]$SpecialExt      = '.wmq01',   # Extension appended to special-format files
    [string]$SpecialFilter   = '*_SPECIAL_*'  # Glob to identify files needing the special extension
)

$Date          = Get-Date -UFormat '%d%m%Y_%H%M'
$WinSCPComFile = Join-Path $ScriptWorkDir 'WinSCP-Command-File.txt'
$WinSCPLog     = Join-Path $ScriptWorkDir "Logs\$Date.log"

if (-not (Test-Path (Join-Path $ScriptWorkDir 'Logs'))) { New-Item (Join-Path $ScriptWorkDir 'Logs') -ItemType Directory | Out-Null }

$StandardFiles = Get-ChildItem "$SourcePath\*" -Include *.pdf, *.xls, *.csv -Exclude $SpecialFilter
$SpecialFiles  = Get-ChildItem "$SourcePath\*" -Include $SpecialFilter

if (-not $StandardFiles -and -not $SpecialFiles) { Write-Host 'No files to upload.'; return }

"open $WinSCPSession" | Out-File $WinSCPComFile -Encoding Default
"CD $RemoteDirectory" | Out-File $WinSCPComFile -Append -Encoding Default

# Rename special files and queue put commands
foreach ($File in $SpecialFiles) {
    $NewName = $File.FullName + $SpecialExt
    Move-Item $File.FullName $NewName
    $Renamed = Get-Item $NewName
    "Put `"$($Renamed.FullName)`" $($Renamed.Name)" | Out-File $WinSCPComFile -Append -Encoding Default
}

# Rename standard files and queue put commands
foreach ($File in $StandardFiles) {
    $NewName = $File.FullName + $StandardExt
    Move-Item $File.FullName $NewName
    $Renamed = Get-Item $NewName
    "Put `"$($Renamed.FullName)`" $($Renamed.Name)" | Out-File $WinSCPComFile -Append -Encoding Default
}

'close' | Out-File $WinSCPComFile -Append -Encoding Default
'exit'  | Out-File $WinSCPComFile -Append -Encoding Default

Start-Process -FilePath $WinSCPExe -ArgumentList "/Script=$WinSCPComFile /log=$WinSCPLog" -Wait
$Log = Get-Content $WinSCPLog

# Process standard files — revert rename if upload not confirmed in log, move to Sent if it was
foreach ($File in $StandardFiles) {
    $RenamedPath = $File.FullName + $StandardExt
    $Marker = "Copying `"$RenamedPath`" to remote directory started."
    if ($Log | Where-Object { $_.EndsWith($Marker) }) {
        $Renames = Get-ChildItem $SourcePath | Where-Object { $_.FullName -like "*$($File.Name)*" }
        Move-Item $Renames.FullName $SentPath
    } else {
        if (Test-Path $RenamedPath) { Move-Item $RenamedPath $File.FullName }  # Revert
    }
}

# Same for special files
foreach ($File in $SpecialFiles) {
    $RenamedPath = $File.FullName + $SpecialExt
    $Marker = "Copying `"$RenamedPath`" to remote directory started."
    if ($Log | Where-Object { $_.EndsWith($Marker) }) {
        $Renames = Get-ChildItem $SourcePath | Where-Object { $_.FullName -like "*$($File.Name)*" }
        Move-Item $Renames.FullName $SentPath
    } else {
        if (Test-Path $RenamedPath) { Move-Item $RenamedPath $File.FullName }
    }
}
