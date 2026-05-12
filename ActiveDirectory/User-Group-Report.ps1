# Description: Generates HTML reports of all AD groups with membership lists and all user accounts, then emails them
# Requirements: ActiveDirectory module
param(
    [string]$SMTPServer  = 'smtp.domain.local',
    [string]$FromAddress = 'ad-reports@domain.local',
    [string]$ToAddress   = 'admin@domain.local',
    [string]$GroupFile   = 'C:\Scripts\ADGroupMembers.html',
    [string]$UserFile    = 'C:\Scripts\ADUsers.html'
)

$Hostname = [System.Net.Dns]::GetHostName()
$Today    = Get-Date -UFormat '%D'
$Start    = Get-Date

$Email          = New-Object Net.Mail.MailMessage
$Email.From     = $FromAddress
$Email.Sender   = $FromAddress
$Email.ReplyTo  = $FromAddress
$Email.To.Add($ToAddress)
$Email.IsBodyHtml = $true

$GroupList = Get-ADGroup -Filter * -Properties * | Sort-Object Created
$UserList  = Get-ADUser  -Filter * -Properties * | Sort-Object Created

$HTMLReportGroup = "<HTML><Title>Group Report for $Today</Title><H1>AD Group Membership as of $Today</H1><BR>"
$HTMLReportUsers = "<HTML><Title>User Report for $Today</Title><H1>AD User Accounts as of $Today</H1><BR>"

foreach ($Group in $GroupList) {
    $DataTable = New-Object System.Data.DataTable
    $DataTable.Columns.Add((New-Object System.Data.DataColumn 'SAMAccountName', ([string])))
    $DataTable.Columns.Add((New-Object System.Data.DataColumn 'DisplayName',    ([string])))

    $HTMLReportGroup += "<Table style='width:900px'><TR><TD>Group Name</TD><TD><B>$($Group.Name)</B></TD></TR><TR><TD>Description</TD><TD><B>$($Group.Description)</B></TD></TR><TR><TD>Date Created</TD><TD><B>$($Group.Created)</B></TD></TR><TR><TD>Date Modified</TD><TD><B>$($Group.Modified)</B></TD></TR></TABLE><BR>"

    foreach ($Member in (Get-ADGroupMember -Identity $Group)) {
        $Row = $DataTable.NewRow()
        $Row.SAMAccountName = $Member.SAMAccountName
        $Row.DisplayName    = $Member.Name
        $DataTable.Rows.Add($Row)
    }

    $HTMLTable = '<style>table,th,td{border:1px solid black;border-collapse:collapse;}</style><table><tr><td>Account Name</td><td>Display Name</td></tr>'
    foreach ($Source in ($DataTable | Sort-Object SAMAccountName)) {
        $HTMLTable += "<tr><td>$($Source.SAMAccountName)</td><td>$($Source.DisplayName)</td></tr>"
    }
    $HTMLTable       += '</table><BR>'
    $HTMLReportGroup += $HTMLTable
}
$HTMLReportGroup | Out-File $GroupFile

$DataTable = New-Object System.Data.DataTable
$DataTable.Columns.Add((New-Object System.Data.DataColumn 'SAMAccountName', ([string])))
$DataTable.Columns.Add((New-Object System.Data.DataColumn 'DisplayName',    ([string])))
$DataTable.Columns.Add((New-Object System.Data.DataColumn 'AccCreated',     ([string])))
$DataTable.Columns.Add((New-Object System.Data.DataColumn 'AccEnabled',     ([string])))

foreach ($User in $UserList) {
    $Row = $DataTable.NewRow()
    $Row.SAMAccountName = $User.SAMAccountName
    $Row.DisplayName    = $User.DisplayName
    $Row.AccCreated     = $User.Created
    $Row.AccEnabled     = $User.Enabled
    $DataTable.Rows.Add($Row)
}

$HTMLTable = '<style>table,th,td{border:1px solid black;border-collapse:collapse;}</style><table><tr><td>Account Name</td><td>Display Name</td><td>Creation Date</td><td>Account Enabled</td></tr>'
foreach ($Source in $DataTable) {
    $HTMLTable += "<tr><td>$($Source.SAMAccountName)</td><td>$($Source.DisplayName)</td><td>$($Source.AccCreated)</td><td>$($Source.AccEnabled)</td></tr>"
}
$HTMLTable       += '</table><BR>'
$HTMLReportUsers += $HTMLTable
$HTMLReportUsers | Out-File $UserFile

$Duration = [Math]::Round((New-TimeSpan -Start $Start -End (Get-Date)).TotalSeconds, 2)
$Email.Subject = "AD Group & User Report - $Today"
$Email.Body    = "AD Group and User report for $Today.<BR><BR>Generated in <I>$Duration</I> seconds by <B>$Hostname</B>."
$Email.Attachments.Add($GroupFile)
$Email.Attachments.Add($UserFile)

$Smtp = New-Object Net.Mail.SmtpClient($SMTPServer)
$Smtp.Send($Email)
