# Description: Enables a remote (cloud) mailbox for an on-premises AD user in a hybrid Exchange environment
# Requirements: Exchange Management Shell on the on-premises Exchange server
# Note: Run this in the Exchange Management Shell — not standard PowerShell
param(
    [Parameter(Mandatory)][string]$PrimarySmtp,
    [Parameter(Mandatory)][string]$DisplayName,
    [Parameter(Mandatory)][string]$TenantDomain,   # e.g. 'contoso.onmicrosoft.com'
    [string]$RoutingAlias                           # defaults to the left-hand side of PrimarySmtp
)

if (-not $RoutingAlias) {
    $RoutingAlias = ($PrimarySmtp -split '@')[0]
}
$RemoteRoutingAddress = "$RoutingAlias@$TenantDomain"

Enable-RemoteMailbox `
    -Identity            $PrimarySmtp `
    -PrimarySmtpAddress  $PrimarySmtp `
    -DisplayName         $DisplayName `
    -RemoteRoutingAddress $RemoteRoutingAddress
