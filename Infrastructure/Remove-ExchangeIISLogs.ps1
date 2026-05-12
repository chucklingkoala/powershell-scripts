# Description: Deletes Exchange V15 and IIS log files older than N days to reclaim disk space
# Requirements: Run as Administrator on the Exchange server, Exchange Server V15 installed
param(
    [int]$RetentionDays      = 1,
    [string]$IISLogPath      = 'C:\inetpub\logs\LogFiles\',
    [string]$ExchangeLogPath = 'C:\Program Files\Microsoft\Exchange Server\V15\Logging\',
    [string]$ETLLogPath1     = 'C:\Program Files\Microsoft\Exchange Server\V15\Bin\Search\Ceres\Diagnostics\ETLTraces\',
    [string]$ETLLogPath2     = 'C:\Program Files\Microsoft\Exchange Server\V15\Bin\Search\Ceres\Diagnostics\Logs'
)

function Remove-OldLogFiles {
    param([string]$TargetFolder)
    if (Test-Path $TargetFolder) {
        $Cutoff = (Get-Date).AddDays(-$RetentionDays)
        $Files  = Get-ChildItem $TargetFolder -Include *.log -Recurse |
                  Where-Object { $_.LastWriteTime -le $Cutoff }
        foreach ($File in $Files) {
            Remove-Item $File.FullName -ErrorAction SilentlyContinue
            Write-Host "Deleted: $($File.FullName)" -ForegroundColor Yellow
        }
    } else {
        Write-Warning "Path not found: $TargetFolder"
    }
}

foreach ($Path in @($IISLogPath, $ExchangeLogPath, $ETLLogPath1, $ETLLogPath2)) {
    Remove-OldLogFiles $Path
}
Write-Host 'Log cleanup complete.' -ForegroundColor Green
