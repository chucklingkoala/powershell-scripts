# Description: Reports all CAS mailboxes with OWA enabled and emails the CSV
# Requirements: Exchange Management Shell
param(
    [string]$SMTPServer  = 'smtp.domain.local',
    [string]$FromAddress = 'exchange-reports@domain.local',
    [string]$ToAddress   = 'admin@domain.local',
    [string]$OutputCSV   = 'C:\Temp\OnPremOWAEnabled.csv'
)

Add-PSSnapin Microsoft.Exchange.Management.PowerShell.E2010 -ErrorAction SilentlyContinue

Get-CASMailbox | Select-Object Name, OWAEnabled | Export-Csv -Path $OutputCSV -NoTypeInformation

$Subject = if (Test-Path $OutputCSV) { 'Exchange On-Prem OWA Enabled Report - SUCCESS' } else { 'Exchange On-Prem OWA Enabled Report - FAILED' }

$Email         = New-Object Net.Mail.MailMessage
$Email.From    = $FromAddress
$Email.Sender  = $FromAddress
$Email.ReplyTo = $FromAddress
$Email.To.Add($ToAddress)
$Email.Subject = $Subject
if (Test-Path $OutputCSV) { $Email.Attachments.Add($OutputCSV) }

$Smtp = New-Object Net.Mail.SmtpClient($SMTPServer)
$Smtp.Send($Email)
