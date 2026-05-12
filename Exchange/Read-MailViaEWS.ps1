# Description: Reads and displays the most recent inbox items from a mailbox using Exchange Web Services (EWS)
# Requirements: EWS Managed API DLL (Microsoft.Exchange.WebServices.dll)
#   Download from: https://www.microsoft.com/en-us/download/details.aspx?id=42951
param(
    [string]$MailboxAddress = 'user@domain.local',
    [string]$EWSDllPath     = 'C:\EWS\Microsoft.Exchange.WebServices.dll',
    [int]$ItemCount         = 5
)

function Write-Color {
    param([String[]]$Text, [ConsoleColor[]]$Color)
    for ($i = 0; $i -lt $Text.Length; $i++) {
        Write-Host $Text[$i] -ForegroundColor $Color[$i] -NoNewLine
    }
    Write-Host
}

[void][Reflection.Assembly]::LoadFile($EWSDllPath)

$service                    = New-Object Microsoft.Exchange.WebServices.Data.ExchangeService
$service.UseDefaultCredentials = $true
$service.AutodiscoverUrl($MailboxAddress)

$inbox = [Microsoft.Exchange.WebServices.Data.Folder]::Bind(
    $service,
    [Microsoft.Exchange.WebServices.Data.WellKnownFolderName]::Inbox
)

$propSet = New-Object Microsoft.Exchange.WebServices.Data.PropertySet(
    [Microsoft.Exchange.WebServices.Data.BasePropertySet]::FirstClassProperties
)
$propSet.RequestedBodyType = [Microsoft.Exchange.WebServices.Data.BodyType]::Text

$items = $inbox.FindItems($ItemCount)

Write-Color -Text 'Unread count: ', $inbox.UnreadCount -Color Yellow, White

foreach ($item in $items.Items) {
    $item.Load($propSet)
    $colors = if ($item.IsRead) { 'Yellow', 'White' } else { 'Red', 'White' }
    $body   = ($item.Body.Text -replace '\s+', ' ')
    $body   = if ($body.Length -gt 100) { $body.Substring(0, 100) + '...' } else { $body }

    Write-Host '=' * 68 -ForegroundColor White
    Write-Color 'From:    ', $item.From.Name    $colors
    Write-Color 'Subject: ', $item.Subject       $colors
    Write-Color 'Body:    ', $body               $colors
    Write-Host '=' * 68 -ForegroundColor White
}
