# Description: Undoes an active Veeam replica failover by stopping the failover for a given VM
# Requirements: Veeam Backup & Replication, VeeamPSSnapIn
param(
    [string]$ReplicaNamePattern = '*',   # Filter to match the replica job (e.g. '*Information Technology*')
    [string]$VMName             = ''     # Specific VM name to undo (leave blank to undo all in matched replica)
)

Add-PSSnapin VeeamPSSnapIn

$Date    = Get-Date
$Replica = Get-VBRReplica | Where-Object { $_.Name -like $ReplicaNamePattern }
$Points  = Get-VBRRestorePoint -Backup $Replica | Where-Object { $_.CreationTime -gt $Date.AddDays(-2) }

if ($VMName) {
    $Points = $Points | Where-Object { $_.VMName -eq $VMName }
}

if ($Points) {
    Stop-VBRReplicaFailover $Points
    Write-Host "Failover undone for: $($Points.VMName -join ', ')" -ForegroundColor Green
} else {
    Write-Warning 'No matching failover restore points found.'
}
