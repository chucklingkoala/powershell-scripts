# Description: Generates an Exchange mailbox usage report (size, quota, items, inbox, sent, deleted)
#              and emails it with a top-10 summary. Outputs full report as HTML attachment.
# Requirements: Exchange Management Shell (Exchange 2016+)
param(
    [string]$SMTPServer    = 'smtp.domain.local',
    [string]$FromAddress   = 'exchange-reports@domain.local',
    [string]$ToAddress     = 'ops@domain.local',
    [string]$MailServer    = 'EXCH01.domain.local',
    [string]$ReportPath    = 'C:\Scripts\Mailbox-Report.html'
)

Add-PSSnapin Microsoft.Exchange.Management.PowerShell.E2010    -ErrorAction SilentlyContinue
Add-PSSnapin Microsoft.Exchange.Management.PowerShell.Setup    -ErrorAction SilentlyContinue
Add-PSSnapin Microsoft.Exchange.Management.PowerShell.Support  -ErrorAction SilentlyContinue

$Hostname  = [System.Net.Dns]::GetHostName()
$Today     = (Get-Date).ToLongDateString()
$Mailboxes = Get-Mailbox -Server $MailServer

$Email         = New-Object Net.Mail.MailMessage
$Email.From    = $FromAddress
$Email.Sender  = $FromAddress
$Email.ReplyTo = $FromAddress
$Email.To.Add($ToAddress)
$Email.IsBodyHtml = $true

$DataTable = New-Object System.Data.DataTable
foreach ($Col in @(
    @('User',      'String'), @('DisplayName', 'String'), @('PrimarySmtp', 'String'),
    @('Size',      'Int32'),  @('Items',        'Int32'),
    @('DelItems',  'Int32'),  @('IBXItems',     'Int32'),  @('SentItems',  'Int32'),
    @('Dumpster',  'String'), @('Quota',        'String'),
    @('Status',    'String'), @('Database',     'String')
)) {
    $DataTable.Columns.Add((New-Object System.Data.DataColumn $Col[0], ([type]$Col[1])))
}

# Look up database quota values to resolve per-mailbox quotas
$DBQuotas = @{}
Get-MailboxDatabase | ForEach-Object {
    $DBQuotas[$_.Name] = $_.ProhibitSendQuota.IsUnlimited ? 'Unlimited' : $_.ProhibitSendQuota.Value.ToMB()
}

foreach ($User in $Mailboxes) {
    $MBXStats      = Get-MailboxStatistics $User
    $MBXFolderStats = Get-MailboxFolderStatistics $User

    $Quota = if ($User.UseDatabaseQuotaDefaults) {
        $DBQuotas[$User.Database.Name] ?? 'Unknown'
    } elseif ($User.ProhibitSendQuota.IsUnlimited) {
        'Unlimited'
    } else {
        $User.ProhibitSendQuota.Value.ToMB()
    }

    $Row              = $DataTable.NewRow()
    $Row.User         = $MBXStats.DisplayName
    $Row.DisplayName  = $User.DisplayName
    $Row.PrimarySmtp  = $User.PrimarySmtpAddress
    $Row.Size         = $MBXStats.TotalItemSize.Value.ToMB()
    $Row.Items        = $MBXStats.ItemCount
    $Row.DelItems     = ($MBXFolderStats | Where-Object FolderPath -eq '/Deleted Items').FolderSize.ToMB()
    $Row.IBXItems     = ($MBXFolderStats | Where-Object FolderPath -eq '/Inbox').ItemsInFolder
    $Row.SentItems    = ($MBXFolderStats | Where-Object FolderPath -eq '/Sent Items').ItemsInFolder
    $Row.Dumpster     = $MBXStats.TotalDeletedItemSize.Value.ToMB()
    $Row.Quota        = $Quota
    $Row.Status       = $MBXStats.StorageLimitStatus
    $Row.Database     = $User.Database.Name
    $DataTable.Rows.Add($Row)
}

$HTMLReport  = "<HTML><Title>Exchange Mailbox Report</Title><H1>Exchange Mailbox Report for $Today</H1><BR>"
$HTMLReport += '<style>table,th,td{border:1px solid black;border-collapse:collapse;}</style>'
$HTMLTable   = '<table style="width:1400px"><tr><td>Mailbox</td><td>Display Name</td><td>SMTP</td><td>Size (MB)</td><td>Dumpster (MB)</td><td>Items</td><td>Inbox Items</td><td>Sent Items</td><td>Deleted Items (MB)</td><td>Quota (MB)</td><td>Status</td><td>Database</td></tr>'
foreach ($Row in ($DataTable | Sort-Object Size -Descending)) {
    $HTMLTable += "<tr><td>$($Row.User)</td><td>$($Row.DisplayName)</td><td>$($Row.PrimarySmtp)</td><td align=right>$($Row.Size) MB</td><td align=right>$($Row.Dumpster) MB</td><td align=right>$($Row.Items)</td><td align=right>$($Row.IBXItems)</td><td align=right>$($Row.SentItems)</td><td align=right>$($Row.DelItems)</td><td align=right>$($Row.Quota) MB</td><td align=right>$($Row.Status)</td><td>$($Row.Database)</td></tr>"
}
$HTMLTable  += '</table><BR>'
$HTMLReport += $HTMLTable
$HTMLReport | Out-File $ReportPath

$TopSizeTable = '<table style="width:500px"><tr><td>Mailbox</td><td>Size (MB)</td><td>Quota (MB)</td><td>% of Quota</td></tr>'
foreach ($Row in ($DataTable | Sort-Object Size -Descending | Select-Object -First 10)) {
    $Pct = if ($Row.Quota -ne 'Unlimited' -and $Row.Quota -gt 0) { '{0:P2}' -f ($Row.Size / $Row.Quota) } else { 'Unlimited' }
    $TopSizeTable += "<tr><td>$($Row.User)</td><td align=right>$($Row.Size) MB</td><td align=right>$($Row.Quota) MB</td><td align=right>$Pct</td></tr>"
}
$TopSizeTable += '</table><BR>'

$TopInboxTable = '<table style="width:400px"><tr><td>Mailbox</td><td>Inbox Items</td></tr>'
foreach ($Row in ($DataTable | Sort-Object IBXItems -Descending | Select-Object -First 10)) {
    $TopInboxTable += "<tr><td>$($Row.User)</td><td align=right>$($Row.IBXItems)</td></tr>"
}
$TopInboxTable += '</table><BR>'

$Email.Subject = 'Exchange Mailbox Usage Report'
$Email.Body    = "<HTML><H3>Exchange Mailbox Report for $Today</H3><P>Full report attached.</P><H4>Top 10 by Mailbox Size</H4>$TopSizeTable<H4>Top 10 by Inbox Item Count</H4>$TopInboxTable<I>Generated by <B>$Hostname</B></I></HTML>"
$Email.Attachments.Add($ReportPath)

$Smtp = New-Object Net.Mail.SmtpClient($SMTPServer)
$Smtp.Send($Email)
