# Description: Interactive menu to start a remote PowerShell session to one of several pre-defined servers.
#              Loads the appropriate module or snapin for each server role automatically.
# Requirements: PowerShell remoting enabled on target servers
param(
    [hashtable]$Servers = @{
        SharePoint   = 'sharepoint.domain.local'
        Exchange     = 'exchange.domain.local'
        DomainController = 'dc01.domain.local'
        BackupServer = 'backup.domain.local'
    }
)

$Cred = Get-Credential -Message 'Enter credentials for remote session'

$Options = $Servers.Keys | ForEach-Object {
    New-Object System.Management.Automation.Host.ChoiceDescription "&$_", "Connect to $($Servers[$_])"
}
$Choices = [System.Management.Automation.Host.ChoiceDescription[]]$Options
$Result  = $Host.UI.PromptForChoice('Remote Session', 'Select target server:', $Choices, 0)
$Target  = @($Servers.Keys)[$Result]
$Server  = $Servers[$Target]

Write-Host "Connecting to $Target ($Server)..." -ForegroundColor Cyan

switch ($Target) {
    'SharePoint' {
        $PSSession = New-PSSession -ComputerName $Server -Credential $Cred
        Invoke-Command -Session $PSSession -ScriptBlock { Add-PSSnapin Microsoft.SharePoint.PowerShell }
        Enter-PSSession -Session $PSSession
    }
    'Exchange' {
        $PSSession = New-PSSession -ConfigurationName Microsoft.Exchange `
                        -ConnectionUri "http://$Server/powershell/" `
                        -Credential $Cred -Authentication Kerberos
        Import-PSSession $PSSession -DisableNameChecking
    }
    'DomainController' {
        $PSSession = New-PSSession -ComputerName $Server -Credential $Cred
        Enter-PSSession -Session $PSSession
    }
    'BackupServer' {
        $PSSession = New-PSSession -ComputerName $Server -Credential $Cred
        Invoke-Command -Session $PSSession -ScriptBlock { Import-Module DataProtectionManager }
        Enter-PSSession -Session $PSSession
    }
}
