# Description: Checks for DPM backup jobs running longer than a threshold and emails an alert
# Requirements: DPM PowerShell module, run on DPM server
param(
    [string]$SMTPServer        = 'smtp.domain.local',
    [string]$FromAddress       = 'dpm-alerts@domain.local',
    [string]$ToAddress         = 'ops@domain.local',
    [string]$ProtectionGroupName = 'Your Protection Group Name',
    [int]$AlertThresholdHours  = 8
)

Invoke-Expression -Command 'C:\Program Files\Microsoft System Center 2012\DPM\DPM\bin\dpmcliinitscript.ps1'

$ProtGrp = Get-ProtectionGroup | Where-Object { $_.FriendlyName -eq $ProtectionGroupName }
$Jobs    = Get-DPMJob -ProtectionGroup $ProtGrp |
           Where-Object { $_.JobCategory -in 'Replication','Validation','ShadowCopy' }
$Running = $Jobs | Where-Object { $_.HasCompleted -eq $false }

if ($Running) {
    $Duration = (Get-Date) - $Running.StartTime
    if ($Duration.TotalHours -gt $AlertThresholdHours) {
        $Email         = New-Object Net.Mail.MailMessage
        $Email.From    = $FromAddress
        $Email.Sender  = $FromAddress
        $Email.ReplyTo = $FromAddress
        $Email.To.Add($ToAddress)
        $Email.Subject = "Long-Running DPM $($Running.JobCategory) Job on '$ProtectionGroupName'"
        $Email.Body    = "A $($Running.JobCategory) job has been running for more than $AlertThresholdHours hours.`nDatasource: $($Running.DataSources)`nStarted: $($Running.StartTime)"

        $Smtp = New-Object Net.Mail.SmtpClient($SMTPServer)
        $Smtp.Send($Email)
    }
}
