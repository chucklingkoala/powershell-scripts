# Description: Deactivates the DR site by unmounting iSCSI from DR servers, restarting them,
#              undoing the Veeam failover, then removing the cloned SAN volumes.
# Requirements: DR servers and Veeam server reachable via PowerShell remoting
param(
    [string]$VeeamServer        = 'dr-backup.domain.local',
    [string]$VeeamUndoScript    = 'C:\Scripts\DR\Undo-VeeamFailover.ps1',
    [string]$SANRemoveScript    = 'C:\Scripts\DR\DR-Remove-Clones.ps1',
    [string]$iSCSIRemoveScript  = 'C:\Scripts\Tools\RemoveAllISCSI.ps1'
)

$DRServers = [ordered]@{
    AppServer1 = 'dr-appserver1.domain.local'
    AppServer2 = 'dr-appserver2.domain.local'
    DBServer1  = 'dr-dbserver1.domain.local'
    DBServer2  = 'dr-dbserver2.domain.local'
}

foreach ($Server in $DRServers.GetEnumerator()) {
    Write-Host "Removing iSCSI on $($Server.Key)..." -ForegroundColor Cyan
    $Session = New-PSSession -ComputerName $Server.Value
    Invoke-Command -Session $Session -FilePath $iSCSIRemoveScript
}

Write-Host 'Restarting DR servers to release volume locks...' -ForegroundColor Yellow
foreach ($Server in $DRServers.GetEnumerator()) {
    $Session = New-PSSession -ComputerName $Server.Value
    Invoke-Command -Session $Session -ScriptBlock { Shutdown -r -t 30 }
}

Write-Host 'Undoing Veeam failover...' -ForegroundColor Cyan
$VeeamSession = New-PSSession -ComputerName $VeeamServer
Invoke-Command -Session $VeeamSession -FilePath $VeeamUndoScript

Write-Host 'Waiting 2 minutes for servers to restart...'
Start-Sleep -Seconds 120

Write-Host 'Removing cloned SAN volumes...' -ForegroundColor Cyan
& $SANRemoveScript

Write-Host 'DR deactivation complete.' -ForegroundColor Green
