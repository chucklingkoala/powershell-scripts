# Description: Updates DNS A records during DR failover or failback by reading Live/DR IP pairs from CSV files.
#              When called from a DR menu with $Global variables set, updates automatically.
#              When run standalone, shows a GUI to select which systems to roll back.
# Requirements: DNSServer module, DNS admin rights on DR DNS server
# CSV format: Host,LiveIP,DRIP (one row per DNS record to update)
param(
    [string]$DNSServer   = 'dc.domain.local',
    [string]$DNSZone     = 'domain.local',
    [string]$CSVFolder   = 'C:\Scripts\DR\CSVs'
)

Import-Module DNSServer

# Map of service names to their CSV files containing Host/LiveIP/DRIP mappings
$ServiceCSVs = @{
    SharePoint  = Join-Path $CSVFolder 'SharePoint-IPs.csv'
    CRM         = Join-Path $CSVFolder 'CRM-IPs.csv'
    AppSystem1  = Join-Path $CSVFolder 'AppSystem1-IPs.csv'
    AppSystem2  = Join-Path $CSVFolder 'AppSystem2-IPs.csv'
    AppSystem3  = Join-Path $CSVFolder 'AppSystem3-IPs.csv'
    AppSystem4  = Join-Path $CSVFolder 'AppSystem4-IPs.csv'
}

$DataTable = New-Object System.Data.DataTable
$DataTable.Columns.Add('Host')
$DataTable.Columns.Add('LiveIP')
$DataTable.Columns.Add('DRIP')

$Failover = $false

# If running from DR menu with global variables, load CSVs automatically (failover mode)
foreach ($Svc in $ServiceCSVs.GetEnumerator()) {
    $GlobalVar = Get-Variable "Global:$($Svc.Key)" -ErrorAction SilentlyContinue
    if ($GlobalVar.Value -eq $true -and (Test-Path $Svc.Value)) {
        $Failover = $true
        foreach ($Line in (Import-Csv $Svc.Value)) {
            $Row = $DataTable.NewRow()
            $Row.Host = $Line.Host; $Row.LiveIP = $Line.LiveIP; $Row.DRIP = $Line.DRIP
            $DataTable.Rows.Add($Row)
        }
    }
}

# If no global vars set, show a GUI to select which systems to roll back (failback mode)
if (-not $Failover) {
    [reflection.assembly]::loadwithpartialname('System.Windows.Forms') | Out-Null
    $form = New-Object System.Windows.Forms.Form
    $form.Text = 'DR DNS Failback'; $form.ClientSize = '266,261'

    $checks = @{}
    $y = 101
    foreach ($Svc in $ServiceCSVs.Keys) {
        $cb = New-Object System.Windows.Forms.CheckBox
        $cb.Text = $Svc; $cb.Location = "33,$y"; $cb.Size = '200,24'
        $form.Controls.Add($cb); $checks[$Svc] = $cb; $y += 30
    }

    $lbl = New-Object System.Windows.Forms.Label
    $lbl.Text = 'Select services to revert DNS to Live IPs:'; $lbl.Location = '12,32'; $lbl.Size = '235,60'
    $form.Controls.Add($lbl)

    $btnOK = New-Object System.Windows.Forms.Button; $btnOK.Text = 'OK'; $btnOK.DialogResult = 1; $btnOK.Location = '33,208'; $btnOK.Size = '75,23'
    $btnCancel = New-Object System.Windows.Forms.Button; $btnCancel.Text = 'Cancel'; $btnCancel.DialogResult = 2; $btnCancel.Location = '143,208'; $btnCancel.Size = '75,23'
    $form.Controls.Add($btnOK); $form.Controls.Add($btnCancel)

    if ($form.ShowDialog() -ne 'OK') { Write-Host 'Cancelled.'; return }

    foreach ($Svc in $checks.GetEnumerator()) {
        if ($Svc.Value.Checked -and (Test-Path $ServiceCSVs[$Svc.Key])) {
            foreach ($Line in (Import-Csv $ServiceCSVs[$Svc.Key])) {
                $Row = $DataTable.NewRow()
                $Row.Host = $Line.Host; $Row.LiveIP = $Line.LiveIP; $Row.DRIP = $Line.DRIP
                $DataTable.Rows.Add($Row)
            }
        }
    }
}

foreach ($Line in $DataTable) {
    $Old = Get-DnsServerResourceRecord -ZoneName $DNSZone -ComputerName $DNSServer -Name $Line.Host
    $New = Get-DnsServerResourceRecord -ZoneName $DNSZone -ComputerName $DNSServer -Name $Line.Host
    $TargetIP = if ($Failover) { $Line.DRIP } else { $Line.LiveIP }
    $New.RecordData.IPv4Address = [System.Net.IPAddress]$TargetIP

    Write-Host "Updating $($Old.HostName): $($Old.RecordData.IPv4Address) → $TargetIP" -ForegroundColor Yellow
    Set-DnsServerResourceRecord -NewInputObject $New -OldInputObject $Old -ZoneName $DNSZone -ComputerName $DNSServer
}

Write-Host "DNS changeover complete. $($DataTable.Rows.Count) record(s) updated." -ForegroundColor Green
