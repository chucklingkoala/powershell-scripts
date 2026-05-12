# Description: Clones inbound EqualLogic SAN replicas to volumes and sets iSCSI ACLs for DR servers.
#              Uses global variables from the DR invocation menu to determine which volumes to clone.
# Requirements: EqualLogic PowerShell Tools (EqlPSTools.dll), Dell EqualLogic PS Series SAN
# Note: Adapt the volume name, replica set name, and iSCSI initiator IQN mappings to your environment.
param(
    [string]$SANGroupAddress = '192.168.100.1',   # EQL group IP
    [PSCredential]$SANCred   = (Get-Credential -Message 'Enter EqualLogic group admin credentials'),
    [string]$EQLModulePath   = 'C:\Program Files\EqualLogic\bin\EqlPSTools.dll',
    [string]$ACLType         = 'volume_and_snapshot'
)

Import-Module $EQLModulePath

# Adapt these mappings — ReplicaSet → CloneVolumeName → iSCSI initiator IQN
$VolumeMappings = @(
    @{ GlobalVar='System1'; ReplicaSet='Server1-Data.1';   VolumeName='DR-Server1-Data';   IQN='iqn.1991-05.com.microsoft:dr-server1.domain.local' }
    @{ GlobalVar='System2'; ReplicaSet='Server2-Data.1';   VolumeName='DR-Server2-Data';   IQN='iqn.1991-05.com.microsoft:dr-server2.domain.local' }
    @{ GlobalVar='System3'; ReplicaSet='Server3-DataD.1';  VolumeName='DR-Server3-DataD';  IQN='iqn.1991-05.com.microsoft:dr-server3.domain.local' }
    @{ GlobalVar='System3'; ReplicaSet='Server3-DataL.1';  VolumeName='DR-Server3-DataL';  IQN='iqn.1991-05.com.microsoft:dr-server3.domain.local' }
)

Connect-EqlGroup -GroupAddress $SANGroupAddress -Credential $SANCred

foreach ($Mapping in $VolumeMappings) {
    $Var = Get-Variable "Global:$($Mapping.GlobalVar)" -ErrorAction SilentlyContinue
    if ($Var.Value -eq $true) {
        $Replicas = Get-EQLInboundReplica -ReplicaSetName $Mapping.ReplicaSet
        $Latest   = $Replicas[$Replicas.Count - 1]

        Write-Host "Cloning $($Mapping.GlobalVar) volume: $($Mapping.VolumeName)" -ForegroundColor Cyan
        New-EQLReplicaClone -ReplicaSetName $Latest.ReplicaSetName -ReplicaName $Latest.ReplicaName -CloneName $Mapping.VolumeName

        Write-Host "Setting ACL for $($Mapping.VolumeName)" -ForegroundColor Cyan
        New-EQLVolumeACL -VolumeName $Mapping.VolumeName -InitiatorName $Mapping.IQN -ACLTargetType $ACLType
    }
}

Disconnect-EqlGroup -GroupAddress $SANGroupAddress
Write-Host 'EQL clone and ACL operations complete.' -ForegroundColor Green
