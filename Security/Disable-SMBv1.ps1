# Description: Disables SMBv1 across all Windows Server domain members via PowerShell remoting.
#              Uses the correct method for each OS version (registry for 2012, feature removal for 2012 R2+).
# Requirements: ActiveDirectory module, PS remoting enabled on target servers, admin rights
Import-Module ActiveDirectory

$Servers = Get-ADComputer -Filter { OperatingSystem -like 'Windows Server*' } -Properties OperatingSystem |
           Select-Object Name, OperatingSystem

$2012    = $Servers | Where-Object { $_.OperatingSystem -like 'Windows Server 2012 Datacenter' }
$2012R2  = $Servers | Where-Object { $_.OperatingSystem -like 'Windows Server 2012 R2*' }
$2016Plus = $Servers | Where-Object { $_.OperatingSystem -like 'Windows Server 2016*' -or $_.OperatingSystem -like 'Windows Server 2019*' -or $_.OperatingSystem -like 'Windows Server 2022*' }

# Server 2012 — disable via registry key (SMBv1 cannot be removed as a feature)
foreach ($SRV in $2012) {
    Invoke-Command -ComputerName $SRV.Name -ScriptBlock {
        Get-SmbServerConfiguration | Select-Object PSComputerName, EnableSMB1Protocol
        Set-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Services\LanmanServer\Parameters' -Name SMB1 -Type DWORD -Value 0 -Force
    }
}

# Server 2012 R2 and later — disable via Windows optional feature (supports online removal)
foreach ($SRV in ($2012R2 + $2016Plus)) {
    Invoke-Command -ComputerName $SRV.Name -ScriptBlock {
        Get-SmbServerConfiguration | Select-Object PSComputerName, EnableSMB1Protocol
        Disable-WindowsOptionalFeature -Online -FeatureName smb1protocol -NoRestart
    }
}
