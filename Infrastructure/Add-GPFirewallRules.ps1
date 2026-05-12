# Description: Adds a list of IP addresses to an existing firewall rule inside a Group Policy Object.
#              Useful for adding vendor/cloud service IP ranges to a centrally managed allowlist.
# Requirements: GroupPolicy and ActiveDirectory modules, GPO admin rights
# Note: Update $GPOName, $RuleName, and $RemoteAddresses to match your environment.
#       Get current vendor IP ranges from the vendor's official documentation.
param(
    [string]$GPOName  = 'FW - Vendor Allowlist',
    [string]$RuleName = 'Allow Vendor Service',
    [string[]]$RemoteAddresses = @(
        # Replace with IP ranges from your vendor's documentation
        '203.0.113.0/24',   # Example: TEST-NET-3 (RFC 5737) — replace with real ranges
        '198.51.100.0/24'   # Example: TEST-NET-2 (RFC 5737) — replace with real ranges
    )
)

Import-Module GroupPolicy
Import-Module ActiveDirectory

$Domain = (Get-ADDomain).DNSRoot
$PDC    = Get-ADDomainController -Discover -Service PrimaryDC -DomainName $Domain

try {
    Write-Host "Opening GPO: $GPOName" -ForegroundColor Yellow
    $GPOSession = Open-NetGPO -PolicyStore "$Domain\$GPOName" -DomainController $PDC.Hostname

    Write-Host "Updating rule: $RuleName" -ForegroundColor Yellow
    Get-NetFirewallRule -GPOSession $GPOSession -DisplayName $RuleName -ErrorAction Stop |
        Get-NetFirewallAddressFilter |
        Set-NetFirewallAddressFilter -RemoteAddress $RemoteAddresses

    Save-NetGPO $GPOSession
    Write-Host "Updated '$RuleName' in '$GPOName' with $($RemoteAddresses.Count) address(es)." -ForegroundColor Green
} catch {
    Write-Error "Failed to update GPO firewall rule: $_"
}
