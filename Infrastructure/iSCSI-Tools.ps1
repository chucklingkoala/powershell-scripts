# Description: Helper functions for querying Windows iSCSI initiator state via WMI —
#              available targets, established sessions, persistent logins, and port mappings.
# Requirements: Run as Administrator, Microsoft iSCSI Initiator service running

function Refresh-Targets {
    (Get-WmiObject -Namespace root/wmi MSiSCSIInitiator_MethodClass).RefreshTargetList() | Out-Null
}

function Get-iSCSIAvailableTargets {
    $TargetClass = Get-WmiObject -Namespace root\wmi MSiSCSIInitiator_TargetClass
    foreach ($Target in $TargetClass) {
        foreach ($Portal in $Target.PortalGroups.Get(0).Portals) {
            [PSCustomObject]@{
                Target     = $Target.TargetName
                TargetNice = $Target.TargetName -replace '^[^:]+:(.+)-\w+\.\w+\.\w+', '$1'
                Address    = $Portal.Address
                Port       = $Portal.Port
            }
        }
    }
}

function Get-iSCSIEstablishedSessions {
    $SessionClass = Get-WmiObject -Namespace root\wmi MSiSCSIInitiator_SessionClass
    foreach ($Session in $SessionClass) {
        if (-not $Session) { continue }
        $Conn = $Session.GetPropertyValue('ConnectionInformation').Get(0)
        [PSCustomObject]@{
            Target           = $Session.TargetName
            TargetNice       = $Session.TargetName -replace '^[^:]+:(.+)-\w+\.\w+\.\w+', '$1'
            Address          = $Conn.TargetAddress
            Port             = $Conn.TargetPort
            InitiatorAddress = $Conn.InitiatorAddress
            Devices          = $Session.Devices
        }
    }
}

function Get-iSCSIPersistentLogins {
    $LoginClass = Get-WmiObject -Namespace root\wmi MSiSCSIInitiator_PersistentLoginClass
    foreach ($Login in $LoginClass) {
        if (-not $Login) { continue }
        [PSCustomObject]@{
            Target         = $Login.TargetName
            TargetNice     = $Login.TargetName -replace '^[^:]+:(.+)-\w+\.\w+\.\w+', '$1'
            Initiator      = $Login.InitiatorInstance
            InitiatorPort  = $Login.InitiatorPortNumber
            TargetIP       = $Login.TargetPortal.Address
            TargetPort     = $Login.TargetPortal.Port
        }
    }
}

function Get-iSCSIPorts {
    $InitiatorInfo = Get-WmiObject -Namespace root\wmi MSiSCSI_PortalInfoClass
    foreach ($Initiator in $InitiatorInfo) {
        foreach ($Port in $Initiator.PortalInformation) {
            [PSCustomObject]@{
                InitiatorName = $Initiator.InstanceName
                Port          = $Port.Port
                IPAddress     = ([Net.IPAddress]$Port.IpAddr.IPV4Address).IPAddressToString
            }
        }
    }
}
