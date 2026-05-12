# Description: Activates a DR site by triggering Veeam failover, cloning SAN replicas,
#              mounting iSCSI volumes on DR servers, then restarting them.
# Requirements: Veeam Backup server and DR servers reachable via PowerShell remoting
# Note: Adapt $DRServers to list your actual DR server hostnames
param(
    [string]$VeeamServer       = 'dr-backup.domain.local',
    [string]$VeeamFailoverScript = 'C:\Scripts\DR\Start-VeeamFailover.ps1',
    [string]$SANCloneScript    = 'C:\Scripts\DR\DR-Clone-Replicas.ps1',
    [string]$iSCSIMountScript  = 'C:\Scripts\Tools\MountAlliSCSI.ps1'
)

# Map of logical server names to DR hostnames (adapt to your environment)
$DRServers = [ordered]@{
    AppServer1 = 'dr-appserver1.domain.local'
    AppServer2 = 'dr-appserver2.domain.local'
    DBServer1  = 'dr-dbserver1.domain.local'
    DBServer2  = 'dr-dbserver2.domain.local'
}

Write-Host 'Step 1: Starting Veeam failover on backup server...' -ForegroundColor Cyan
$VeeamSession = New-PSSession -ComputerName $VeeamServer
Invoke-Command -Session $VeeamSession -FilePath $VeeamFailoverScript

Write-Host 'Step 2: Cloning SAN replica volumes...' -ForegroundColor Cyan
& $SANCloneScript

Write-Host 'Step 3: Waiting 60 seconds for clone operations...'
Start-Sleep -Seconds 60

foreach ($Server in $DRServers.GetEnumerator()) {
    Write-Host "Step 4: Mounting iSCSI on $($Server.Key) ($($Server.Value))..." -ForegroundColor Cyan
    $Session = New-PSSession -ComputerName $Server.Value
    Invoke-Command -Session $Session -FilePath $iSCSIMountScript
}

Write-Host 'Step 5: Restarting DR servers (30-second countdown)...' -ForegroundColor Yellow
foreach ($Server in $DRServers.GetEnumerator()) {
    $Session = New-PSSession -ComputerName $Server.Value
    Invoke-Command -Session $Session -ScriptBlock { Shutdown -r -t 30 }
    Write-Host "  Restart issued to $($Server.Key)"
}

Write-Host 'DR activation complete. Monitor servers for successful restart and volume attachment.' -ForegroundColor Green
