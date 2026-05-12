# Description: Retrieves the internal TLS certificate configured on each Exchange mailbox server
#              and displays subject, friendly name, thumbprint, and expiry date
# Requirements: ActiveDirectory module, Exchange Management Shell or remote Exchange session
param(
    [string]$ExchangeServer = $env:COMPUTERNAME
)

$ExistingSessions = Get-PSSession
if ($ExistingSessions.ConfigurationName -notcontains 'Microsoft.Exchange') {
    $Session = New-PSSession -ConfigurationName Microsoft.Exchange `
                             -ConnectionUri "http://$ExchangeServer/PowerShell/" `
                             -Authentication Kerberos
    Import-PSSession $Session -DisableNameChecking
}

$ExchangeServers = Get-ExchangeServer | Where-Object { $_.ServerRole -like '*mailbox*' } |
                   Select-Object Name, DistinguishedName

$Results = foreach ($Server in $ExchangeServers) {
    $TransportCert = (Get-ADObject -Identity $Server.DistinguishedName -Properties msExchServerInternalTLSCert).msExchServerInternalTLSCert
    $Cert = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2
    $Cert.Import([Convert]::FromBase64String([Convert]::ToBase64String($TransportCert)))

    $Server | Add-Member -MemberType NoteProperty -Name TLSCertSubject      -Value $Cert.Subject      -PassThru |
              Add-Member -MemberType NoteProperty -Name TLSCertFriendlyName -Value $Cert.FriendlyName -PassThru |
              Add-Member -MemberType NoteProperty -Name TLSCertThumbprint   -Value $Cert.Thumbprint   -PassThru |
              Add-Member -MemberType NoteProperty -Name TLSCertExpiry       -Value $Cert.NotAfter     -PassThru
}

$Results | Out-GridView -Title 'Exchange Internal TLS Certificates'
