# Description: Configures iSCSI network adapter IPs based on the management IP of the host.
#              Derives iSCSI IPs from the last two octets of the management IP.
# Requirements: Run as Administrator, iSCSI NICs named '*ISCSI 1*' and '*ISCSI 2*'
# Adapt: Change $iSCSISubnet1 and $iSCSISubnet2 to match your storage network subnets.
param(
    [string]$ManagementInterfacePattern = '*Management',
    [string]$iSCSIInterface1Pattern     = '*ISCSI 1',
    [string]$iSCSIInterface2Pattern     = '*ISCSI 2',
    [string]$iSCSISubnet1               = '192.168.200.1',  # First three octets + host portion
    [string]$iSCSISubnet2               = '192.168.200.2',
    [int]$PrefixLength                  = 24
)

$MgmtIP = Get-NetIPAddress | Where-Object { $_.InterfaceAlias -like $ManagementInterfacePattern -and $_.AddressFamily -eq 'IPv4' }
$HostSuffix = $MgmtIP.IPAddress.Substring($MgmtIP.IPAddress.Length - 2)

$IP_iSCSI1 = $iSCSISubnet1 + $HostSuffix
$IP_iSCSI2 = $iSCSISubnet2 + $HostSuffix

$INT1 = Get-NetIPAddress | Where-Object { $_.InterfaceAlias -like $iSCSIInterface1Pattern -and $_.AddressFamily -eq 'IPv4' }
$INT2 = Get-NetIPAddress | Where-Object { $_.InterfaceAlias -like $iSCSIInterface2Pattern -and $_.AddressFamily -eq 'IPv4' }

New-NetIPAddress -InterfaceAlias $INT1.InterfaceAlias -IPAddress $IP_iSCSI1 -PrefixLength $PrefixLength
New-NetIPAddress -InterfaceAlias $INT2.InterfaceAlias -IPAddress $IP_iSCSI2 -PrefixLength $PrefixLength

Write-Host "iSCSI IPs assigned: $IP_iSCSI1 / $IP_iSCSI2"
