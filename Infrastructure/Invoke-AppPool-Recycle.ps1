# Description: Recycles all IIS application pools for all sites on the local server, then emails confirmation
# Requirements: WebAdministration module, IIS installed
param(
    [string]$SMTPServer  = 'smtp.domain.local',
    [string]$FromAddress = 'iis-maintenance@domain.local',
    [string]$ToAddress   = 'ops@domain.local'
)

Import-Module WebAdministration

$Hostname = [System.Net.Dns]::GetHostName()
$Pools    = (Get-Item 'IIS:\Sites\*' | Select-Object applicationPool).applicationPool

foreach ($AppPool in $Pools) {
    Restart-WebAppPool $AppPool
    Write-Host "Recycled: $AppPool"
}

$Email         = New-Object Net.Mail.MailMessage
$Email.From    = $FromAddress
$Email.Sender  = $FromAddress
$Email.ReplyTo = $FromAddress
$Email.To.Add($ToAddress)
$Email.IsBodyHtml = $true
$Email.Subject = 'IIS App Pool Recycle Complete'
$Email.Body    = "All application pools on <B>$Hostname</B> have been recycled."

$Smtp = New-Object Net.Mail.SmtpClient($SMTPServer)
$Smtp.Send($Email)
