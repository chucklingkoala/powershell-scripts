# Description: Monitors Exchange DAG database copy status and emails an alert when a copy is not Mounted
# Requirements: Exchange Management Shell, run as scheduled task
param(
    [string]$SMTPServer   = 'smtp.domain.local',
    [string]$FromAddress  = 'exchange-alerts@domain.local',
    [string]$ToAddress    = 'ops@domain.local',
    [string]$PrimaryServer   = 'EXCH01',
    [string]$FailoverServer  = 'DR-EXCH01',
    [string]$TraceFile       = 'C:\Scripts\DAG-Trace.log'
)

Add-PSSnapin Microsoft.Exchange.Management.PowerShell.E2010 -ErrorAction SilentlyContinue

$Email         = New-Object Net.Mail.MailMessage
$Email.From    = $FromAddress
$Email.Sender  = $FromAddress
$Email.ReplyTo = $FromAddress
$Email.To.Add($ToAddress)
$Email.IsBodyHtml = $true

$LiveCopies   = Get-MailboxDatabaseCopyStatus -Server $PrimaryServer
$MountedCount = ($LiveCopies | Where-Object { $_.Status -eq 'Mounted' }).Count

if ($MountedCount -ne $LiveCopies.Count) {
    $FailedCopies = $LiveCopies | Where-Object { $_.Status -ne 'Mounted' }

    $HTMLTable  = '<style>table,th,td{border:1px solid black;border-collapse:collapse;}</style>'
    $HTMLTable += '<table style="width:800px"><tr><td>Database</td><td>Status</td></tr>'
    foreach ($Copy in $FailedCopies) {
        $HTMLTable += "<tr><td>$($Copy.Name)</td><td>$($Copy.Status)</td></tr>"
    }
    $HTMLTable += '</table><BR>'

    $Email.Subject = "Exchange DAG Alert: Database copy not Mounted on $PrimaryServer"
    $Email.Body    = "<P>One or more database copies on <B>$PrimaryServer</B> are not Mounted.</P>$HTMLTable<P>Check DAG health immediately.</P>"

    $Smtp = New-Object Net.Mail.SmtpClient($SMTPServer)
    $Smtp.Send($Email)
}
