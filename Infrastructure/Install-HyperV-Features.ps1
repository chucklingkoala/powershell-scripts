# Description: Installs Hyper-V, Failover Clustering, and Multipath I/O features on a Windows Server
# Requirements: Run as Administrator, Windows Server with Hyper-V support
# Note: The -Restart flag on Install-WindowsFeature will automatically reboot after install.
Install-WindowsFeature -Name Failover-Clustering -IncludeManagementTools -IncludeAllSubFeature
Add-WindowsFeature    -Name Multipath-IO
Install-WindowsFeature -Name Hyper-V             -IncludeManagementTools -Restart
