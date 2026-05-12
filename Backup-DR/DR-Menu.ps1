# Description: GUI-driven DR invocation menu. Operator selects which systems and departments to fail
#              over, then this script sets global variables and calls the Veeam/storage failover scripts.
# Requirements: Windows Forms, PowerShell remoting to Veeam and DR servers
# Usage: Adapt the system list and $DRScriptPath values to your environment.
param(
    [string]$DRScriptPath    = 'C:\Scripts\DR',
    [string]$VeeamServer     = 'dr-backup.domain.local'
)

# --- Systems available for DR failover (adapt labels and global variable names) ---
$Systems = [ordered]@{
    System1   = 'Application Server 1'
    System2   = 'Application Server 2'
    System3   = 'Database Server 1'
    System4   = 'Database Server 2'
    SharePoint = 'SharePoint'
    CRM        = 'CRM'
    UserVMs    = 'User Virtual Machines'
}

# --- Departments for user VM failover ---
$Departments = [ordered]@{
    IT          = 'Technology'
    Dev         = 'Developers'
    Admin       = 'Admin'
    Compliance  = 'Compliance & Risk'
    Finance     = 'Finance'
    InvTeam     = 'Investment Team'
    InvServices = 'Investor Services'
    PortAcct    = 'Portfolio Accounting'
    UnitReg     = 'Unit Registry'
}

[reflection.assembly]::loadwithpartialname('System.Drawing')    | Out-Null
[reflection.assembly]::loadwithpartialname('System.Windows.Forms') | Out-Null

$form = New-Object System.Windows.Forms.Form
$form.Text = 'DR Invocation Menu'; $form.ClientSize = '400,520'; $form.StartPosition = 1

$title = New-Object System.Windows.Forms.Label
$title.Text = 'DR Invocation'; $title.Font = New-Object System.Drawing.Font('Segoe UI', 12, 1); $title.Location = '13,13'; $title.Size = '200,26'
$form.Controls.Add($title)

$instruct = New-Object System.Windows.Forms.Label
$instruct.Text = "Select the systems to bring online at DR, then click OK.`nIn a test invocation ensure the Test Invocation checkbox is ticked."
$instruct.Location = '13,42'; $instruct.Size = '370,40'
$form.Controls.Add($instruct)

# Systems group
$sysGroup = New-Object System.Windows.Forms.GroupBox
$sysGroup.Text = 'Systems'; $sysGroup.Location = '13,90'; $sysGroup.Size = '370,180'
$form.Controls.Add($sysGroup)

$sysCBs = @{}; $y = 20
foreach ($Sys in $Systems.GetEnumerator()) {
    $cb = New-Object System.Windows.Forms.CheckBox; $cb.Text = $Sys.Value; $cb.Location = "15,$y"; $cb.Size = '160,22'; $y += 26
    $sysGroup.Controls.Add($cb); $sysCBs[$Sys.Key] = $cb
}

# Departments group
$dptGroup = New-Object System.Windows.Forms.GroupBox
$dptGroup.Text = 'Departments (User VMs)'; $dptGroup.Location = '13,280'; $dptGroup.Size = '370,165'
$form.Controls.Add($dptGroup)

$dptCBs = @{}; $y = 20; $x = 15
foreach ($Dept in $Departments.GetEnumerator()) {
    $cb = New-Object System.Windows.Forms.CheckBox; $cb.Text = $Dept.Value; $cb.Location = "$x,$y"; $cb.Size = '165,22'; $y += 26
    if ($y -gt 130) { $y = 20; $x = 195 }
    $dptGroup.Controls.Add($cb); $dptCBs[$Dept.Key] = $cb
}

$testCB = New-Object System.Windows.Forms.CheckBox
$testCB.Text = 'Test Invocation (safe mode)'; $testCB.Location = '13,453'; $testCB.Size = '250,24'; $testCB.Checked = $true
$form.Controls.Add($testCB)

$btnOK     = New-Object System.Windows.Forms.Button; $btnOK.Text = 'OK';     $btnOK.Location = '100,480'; $btnOK.Size = '80,28'; $btnOK.DialogResult = 1
$btnCancel = New-Object System.Windows.Forms.Button; $btnCancel.Text = 'Cancel'; $btnCancel.Location = '200,480'; $btnCancel.Size = '80,28'; $btnCancel.DialogResult = 2
$form.Controls.Add($btnOK); $form.Controls.Add($btnCancel)

$form.ShowDialog() | Out-Null

if ($form.DialogResult -ne 'OK') { Write-Host 'DR invocation cancelled.' -ForegroundColor Red; return }

$confirm = $Host.UI.PromptForChoice('Confirm DR Start', 'Start the DR invocation? This should not be interrupted once started.', @('&Yes','&No'), 1)
if ($confirm -eq 1) { Write-Host 'Aborted.'; return }

# Set global variables based on selections
foreach ($Sys in $sysCBs.GetEnumerator())   { Set-Variable -Name "Global:$($Sys.Key)"   -Value $Sys.Value.Checked   -Scope Global }
foreach ($Dept in $dptCBs.GetEnumerator()) { Set-Variable -Name "Global:Veeam$($Dept.Key)" -Value $Dept.Value.Checked -Scope Global }
$Global:TestInvoke = $testCB.Checked
$Global:Veeam = ($dptCBs.Values | Where-Object Checked).Count -gt 0 -or $sysCBs['UserVMs'].Checked

foreach ($Sys in $sysCBs.GetEnumerator()) {
    if ($Sys.Value.Checked) { Write-Host "$($Sys.Value.Text) selected" -ForegroundColor Green }
}

$confirmFinal = $Host.UI.PromptForChoice('Final Confirmation', 'Selections confirmed above. Proceed?', @('&Yes','&No'), 1)
if ($confirmFinal -eq 1) { Write-Host 'Aborted.'; return }

Write-Host 'Starting DR activation...' -ForegroundColor Cyan

if ($Global:Veeam) {
    Write-Host 'Invoking Veeam failover on backup server...'
    $VeeamSession = New-PSSession -ComputerName $VeeamServer
    Invoke-Command -Session $VeeamSession -FilePath "$DRScriptPath\Start-VeeamFailover.ps1"
}

$NeedsStorage = $sysCBs.GetEnumerator() | Where-Object { $_.Value.Checked -and $_.Key -ne 'UserVMs' }
if ($NeedsStorage) {
    Write-Host 'Invoking SAN clone operations...'
    & "$DRScriptPath\DR-Clone-Replicas.ps1"
}

Write-Host 'DR Invocation complete. Check server status and logs.' -ForegroundColor Green
