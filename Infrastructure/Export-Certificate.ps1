# Description: Exports user certificates (matching a template filter) as password-protected PFX files
#              and emails each user their certificate with a randomly generated password.
# Requirements: Run in user context or as the user whose certificates should be exported
param(
    [string]$SMTPServer       = 'smtp.domain.local',
    [string]$FromAddress      = 'certificates@domain.local',
    [string]$TemplateFilter   = '*User*',
    [string]$ExportFolder     = "$env:USERPROFILE\PKI\",
    [string]$EmailSubject     = 'Your Wireless Access Certificate',
    [string]$EmailBodyTemplate = 'Attached is your user certificate. The PFX password is: {0}'
)

Add-Type -AssemblyName System.Web
$Secret = [System.Web.Security.Membership]::GeneratePassword(12, 2)

function Get-CertificateTemplate {
    param([Security.Cryptography.X509Certificates.X509Certificate2]$Cert)
    process {
        $Template = $Cert.Extensions | Where-Object { $_.Oid.Value -in '1.3.6.1.4.1.311.20.2','1.3.6.1.4.1.311.21.7' }
        $Cert | Add-Member -Name Template -MemberType NoteProperty -Value $Template.Format(1) -PassThru
    }
}

if (-not (Test-Path $ExportFolder)) { New-Item -Path $ExportFolder -ItemType Directory | Out-Null }

$Certs = Get-ChildItem Cert:\CurrentUser\My |
         Where-Object { $_.HasPrivateKey } |
         Get-CertificateTemplate |
         Where-Object { $_.Template -like $TemplateFilter }

foreach ($Cert in $Certs) {
    $IDX_CN     = $Cert.Subject.IndexOf('CN=') + 3
    $IDX_OU     = $Cert.Subject.IndexOf(', OU=')
    $IDX_Email  = $Cert.Subject.IndexOf('E=') + 2
    $IDX_EmailEnd = $Cert.Subject.IndexOf(', CN=')
    $CommonName = $Cert.Subject.Substring($IDX_CN, $IDX_OU - $IDX_CN)
    $EmailAddr  = $Cert.Subject.Substring($IDX_Email, $IDX_EmailEnd - $IDX_Email)
    $PFXPath    = Join-Path $ExportFolder "$CommonName.pfx"

    [System.IO.File]::WriteAllBytes($PFXPath, $Cert.Export('PFX', $Secret))

    $Email         = New-Object Net.Mail.MailMessage
    $Email.From    = $FromAddress
    $Email.Sender  = $FromAddress
    $Email.ReplyTo = $FromAddress
    $Email.To.Add($EmailAddr)
    $Email.IsBodyHtml = $true
    $Email.Subject = $EmailSubject
    $Email.Body    = $EmailBodyTemplate -f $Secret
    $Email.Attachments.Add($PFXPath)

    $Smtp = New-Object Net.Mail.SmtpClient($SMTPServer)
    $Smtp.Send($Email)
    Write-Host "Certificate sent to: $EmailAddr"
}
