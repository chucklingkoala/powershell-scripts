# Description: Rotates a wildcard certificate on Exchange — imports new cert, updates Send/Receive
#              connectors, enables on all Exchange services, then removes the old cert.
# Requirements: Exchange Management Shell, certificate PFX file, run on Exchange server
param(
    [Parameter(Mandatory)][string]$CertPath,        # Path to .pfx file
    [Parameter(Mandatory)][string]$NewThumbprint,   # Thumbprint of new cert
    [Parameter(Mandatory)][string]$OldThumbprint,   # Thumbprint of cert being replaced
    [string]$WildcardDomain = '*.domain.local'      # Used to match connectors
)

Add-PSSnapin Microsoft.Exchange.Management.PowerShell.SnapIn -ErrorAction SilentlyContinue

$CertPass = Read-Host -Prompt 'Enter certificate PFX password' -AsSecureString

# Import the certificate if it is not already installed
if (-not (Get-ExchangeCertificate -Thumbprint $NewThumbprint -ErrorAction SilentlyContinue)) {
    Get-ExchangeServer | Import-ExchangeCertificate `
        -FileData ([System.IO.File]::ReadAllBytes($CertPath)) `
        -PrivateKeyExportable:$true `
        -Password $CertPass
}

$NewCert  = Get-ExchangeCertificate -Thumbprint $NewThumbprint
$TLSName  = "<i>$($NewCert.Issuer)<s>$($NewCert.Subject)"

# Apply new cert to all Exchange services (SMTP, IIS, POP, IMAP, etc.)
$CertServices = Get-ExchangeCertificate | Where-Object { $_.Thumbprint -eq $OldThumbprint } | Select-Object -ExpandProperty Services
Get-ExchangeServer | Enable-ExchangeCertificate -Thumbprint $NewThumbprint -Services $CertServices -Force

# Update Send and Receive connectors that reference the old wildcard
Get-SendConnector    | Where-Object { $_.TlsCertificateName -like "*$WildcardDomain*" -and $_.Enabled } | Set-SendConnector    -TlsCertificateName $TLSName
Get-ReceiveConnector | Where-Object { $_.TlsCertificateName -like "*$WildcardDomain*" -and $_.Enabled } | Set-ReceiveConnector -TlsCertificateName $TLSName

# Restart transport to pick up new cert
Get-Service 'MSExchangeTransport' | Restart-Service

# Remove old certificate
Remove-ExchangeCertificate -Thumbprint $OldThumbprint -Confirm:$false
Write-Host "Certificate rotation complete. New thumbprint: $NewThumbprint"
