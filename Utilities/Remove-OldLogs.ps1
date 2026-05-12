# Description: Deletes log files older than N days from a scripts/logs folder
# Requirements: Write access to the log folder
param(
    [string]$LogFolder    = 'C:\Scripts',
    [int]$RetentionDays   = 3
)

Get-ChildItem $LogFolder -Filter '*.log' -File -Recurse |
    Where-Object { $_.LastWriteTime -le (Get-Date).AddDays(-$RetentionDays) -and -not $_.PSIsContainer } |
    Remove-Item -Force
