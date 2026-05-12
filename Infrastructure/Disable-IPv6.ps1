# Description: Disables IPv6 binding on all Intel network adapters
# Requirements: Run as Administrator
param(
    [string]$AdapterFilter = 'Intel*'   # Adjust to match your NIC naming convention
)

$NICs = Get-NetAdapter | Where-Object { $_.InterfaceDescription -like $AdapterFilter }
foreach ($NIC in $NICs) {
    Get-NetAdapterBinding -Name $NIC.Name -ComponentID 'ms_tcpip6' | Disable-NetAdapterBinding
    Write-Host "IPv6 disabled on: $($NIC.Name)"
}
