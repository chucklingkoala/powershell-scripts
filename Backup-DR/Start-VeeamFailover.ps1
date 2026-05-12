# Description: Starts Veeam replica failover for selected groups of VMs and Failover Plans.
#              Uses global variables set by a parent DR menu script to determine which systems to fail over.
# Requirements: Veeam Backup & Replication v9.0+, VeeamPSSnapIn
# Usage: Called by the DR-Menu.ps1 or invoked with $Global variables pre-set
Add-PSSnapin VeeamPSSnapIn

$Date = Get-Date

# --- Adjust these replica/failover-plan names to match your Veeam environment ---
$ReplicaGroups = @{
    IT         = '*Information Technology*'
    Dev        = '*Developers*'
    Admin      = '*Admin*'
    Compliance = '*Compliance*'
    Finance    = '*Finance*'
    InvTeam    = '*Investment Team*'
    InvServices = '*Investor Services*'
    PortAcct   = '*Portfolio Accounting*'
    UnitReg    = '*Unit Registry*'
}

$FailoverPlans = @{
    System1 = 'System1-FailoverPlan'
    System2 = 'System2-FailoverPlan'
    System3 = 'System3-FailoverPlan'
    System4 = 'System4-FailoverPlan'
    System5 = 'System5-FailoverPlan'
}

function Start-GroupFailover {
    param([string]$GroupKey, [string]$Pattern)
    $Replica = Get-VBRReplica | Where-Object { $_.Name -like $Pattern }
    $RP      = Get-VBRRestorePoint -Backup $Replica | Where-Object { $_.CreationTime -gt $Date.AddDays(-2) }
    if ($RP) {
        Write-Host "Starting failover: $GroupKey" -ForegroundColor Green
        Start-VBRReplicaFailover -RestorePoint $RP
    } else {
        Write-Warning "No recent restore points found for $GroupKey"
    }
}

# --- Test invocation: fail over a single test VM first ---
if ($Global:TestInvoke -and $Global:Veeam) {
    Write-Host 'Test invocation: failing over single test VM' -ForegroundColor Yellow
    $TestReplica = Get-VBRReplica | Where-Object { $_.Name -like $ReplicaGroups.IT }
    $TestRP      = Get-VBRRestorePoint -Backup $TestReplica | Where-Object { $_.CreationTime -gt $Date.AddDays(-2) } | Select-Object -First 1
    Start-VBRReplicaFailover $TestRP
}

# --- Department VM failovers ---
if ($Global:Veeam) {
    $confirm = $Host.UI.PromptForChoice('Confirm Failover', 'Start Veeam failover? Do not proceed in a test without selecting Test Invocation.', @('&Yes','&No'), 1)
    if ($confirm -eq 1) { Write-Host 'Aborted.'; return }

    foreach ($Key in @('IT','Dev','Admin','Compliance','Finance','InvTeam','InvServices','PortAcct','UnitReg')) {
        $VarName = "Global:Veeam$Key"
        if ((Get-Variable $VarName -ErrorAction SilentlyContinue).Value -eq $true) {
            Start-GroupFailover $Key $ReplicaGroups[$Key]
        }
    }
}

# --- Failover Plan activations ---
foreach ($Plan in $FailoverPlans.GetEnumerator()) {
    $VarName = "Global:$($Plan.Key)"
    if ((Get-Variable $VarName -ErrorAction SilentlyContinue).Value -eq $true) {
        Write-Host "Starting Failover Plan: $($Plan.Key)" -ForegroundColor Green
        $FP = Get-VBRFailoverPlan -Name $Plan.Value
        Start-VBRFailoverPlan -FailoverPlan $FP
    }
}
