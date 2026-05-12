# Description: Daily AD health report using Testimo and PSWriteHTML — emails colour-coded test results
# Requirements:
#   Install-Module PSWriteHTML -Force
#   Install-Module Testimo -AllowClobber -Force
param(
    [string]$SMTPServer  = 'smtp.domain.local',
    [string]$FromAddress = 'ad-reports@domain.local',
    [string]$ToAddress   = 'admin@domain.local'
)

$Results = Invoke-Testimo -Sources DCDiagnostics -ReturnResults

Email {
    EmailHeader {
        EmailFrom    -Address $FromAddress
        EmailTo      -Addresses $ToAddress
        EmailServer  -Server $SMTPServer
        EmailSubject -Subject 'Daily AD Report'
    }
    EmailBody -FontFamily 'Calibri' -Size 15 {
        EmailText -Text 'Summary of Active Directory Tests' -Color None, Blue -LineBreak
        EmailTable -DataTable $Results {
            EmailTableCondition -ComparisonType 'string' -Name 'Status' -Operator eq -Value 'True' -BackgroundColor Green -Color White -Inline -Row
            EmailTableCondition -ComparisonType 'string' -Name 'Status' -Operator ne -Value 'True' -BackgroundColor Red  -Color White -Inline -Row
        } -HideFooter
    }
} -AttachSelf -Supress $false
