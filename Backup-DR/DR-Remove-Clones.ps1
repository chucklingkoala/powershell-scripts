# Description: Takes cloned EqualLogic volumes offline and removes them after DR deactivation
# Requirements: EqualLogic PowerShell Tools (EqlPSTools.dll), Dell EqualLogic PS Series SAN
param(
    [string]$SANGroupAddress = '192.168.100.1',
    [PSCredential]$SANCred   = (Get-Credential -Message 'Enter EqualLogic group admin credentials'),
    [string]$EQLModulePath   = 'C:\Program Files\EqualLogic\bin\EqlPSTools.dll'
)

# List of cloned volume names to remove — adapt to match your DR-Clone-Replicas.ps1 mappings
$CloneVolumes = @(
    'DR-Server1-Data'
    'DR-Server2-Data'
    'DR-Server3-DataD'
    'DR-Server3-DataL'
)

Import-Module $EQLModulePath
Connect-EqlGroup -GroupAddress $SANGroupAddress -Credential $SANCred

foreach ($Volume in $CloneVolumes) {
    Write-Host "Taking offline and removing: $Volume" -ForegroundColor Yellow
    Set-EQLVolume    -VolumeName $Volume -OnlineStatus offline
    Remove-EQLVolume -VolumeName $Volume -Force
}

Disconnect-EqlGroup -GroupAddress $SANGroupAddress
Write-Host 'Clone removal complete.' -ForegroundColor Green
