# Description: Sends an email via Exchange Web Services (EWS) using the current user's credentials
# Requirements: EWS Managed API DLL (Microsoft.Exchange.WebServices.dll)
param(
    [string]$MailboxAddress = 'sender@domain.local',
    [string]$ToAddress      = 'recipient@domain.local',
    [string]$Subject        = 'Test email via EWS',
    [string]$Body           = 'Sent from PowerShell via EWS.',
    [string]$EWSDllPath     = 'C:\EWS\Microsoft.Exchange.WebServices.dll'
)

[void][Reflection.Assembly]::LoadFile($EWSDllPath)

$service = New-Object Microsoft.Exchange.WebServices.Data.ExchangeService
$service.UseDefaultCredentials = $true
$service.AutodiscoverUrl($MailboxAddress, { $true })

$message = New-Object Microsoft.Exchange.WebServices.Data.EmailMessage($service)
$message.Subject = $Subject
$message.Body    = $Body
$message.ToRecipients.Add($ToAddress)
$message.Send()
