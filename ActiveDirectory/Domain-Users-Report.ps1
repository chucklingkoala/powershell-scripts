# Description: Generates an HTML report of all Domain Users with account status, password status,
#              and last logon time, then emails it. Uses native AD module (no Quest dependency).
# Requirements: ActiveDirectory module, SMTP relay access
param(
    [string]$SMTPServer  = 'smtp.domain.local',
    [string]$FromAddress = 'audit-trail@domain.local',
    [string]$ToAddress   = 'admin@domain.local',
    [string]$ADGroup     = 'Domain Users',
    [string]$ReportPath  = 'C:\Scripts\Weekly Reports\Domain-Users.html'
)

Import-Module ActiveDirectory

$Today      = Get-Date -UFormat '%d-%m-%y'
$ReportName = 'Domain Users Report'

$GroupMembers = Get-ADGroupMember -Identity $ADGroup | Where-Object { $_.objectClass -eq 'user' }
$UserList     = $GroupMembers | Get-ADUser -Properties DisplayName, GivenName, Surname, EmailAddress, Enabled, PasswordExpired, PasswordLastSet, PasswordNeverExpires, LastLogon, LastLogonTimestamp, AccountExpires, 'msDS-UserPasswordExpiryTimeComputed'

$Email         = New-Object Net.Mail.MailMessage
$Email.From    = $FromAddress; $Email.Sender = $FromAddress; $Email.ReplyTo = $FromAddress
$Email.To.Add($ToAddress); $Email.IsBodyHtml = $true

$HTMLReport  = "<HTML><Title>$ReportName for $Today</Title><H1>$ReportName for $Today</H1><BR>"
$HTMLTable   = '<style>table,th,td{border:1px solid black;border-collapse:collapse;}</style><table><tr><td>Account Name</td><td>First Name</td><td>Last Name</td><td>Email</td><td>Account Enabled?</td><td>Password Status</td><td>Last Logon</td></tr>'

foreach ($User in $UserList) {
    $PasswordStatus = switch ($true) {
        $User.PasswordExpired                                                                              { 'Expired' }
        $User.PasswordNeverExpires                                                                         { 'Never Expires' }
        ($User.PasswordExpired -eq $false -and -not $User.PasswordNeverExpires -and $User.PasswordLastSet -eq 0) { 'Must change at next logon' }
        default {
            $Expiry = [datetime]::FromFileTime($User.'msDS-UserPasswordExpiryTimeComputed')
            "Expires: $($Expiry.ToString('dd/MM/yyyy HH:mm:ss'))"
        }
    }

    $LastLogon = if ($User.LastLogonTimestamp) {
        [datetime]::FromFileTime($User.LastLogonTimestamp).ToString('dddd, dd MMMM yyyy HH:mm:ss')
    } else { 'Never' }

    $HTMLTable += "<tr><td>$($User.Name)</td><td>$($User.GivenName)</td><td>$($User.Surname)</td><td>$($User.EmailAddress)</td><td>$($User.Enabled)</td><td>$PasswordStatus</td><td>$LastLogon</td></tr>"
}
$HTMLTable  += '</table><BR>'
$HTMLReport += $HTMLTable

if (-not (Test-Path (Split-Path $ReportPath))) { New-Item (Split-Path $ReportPath) -ItemType Directory | Out-Null }
$HTMLReport | Out-File $ReportPath

$Email.Subject = "Weekly $ReportName"
$Email.Body    = $HTMLReport

$Smtp = New-Object Net.Mail.SmtpClient($SMTPServer)
$Smtp.Send($Email)
