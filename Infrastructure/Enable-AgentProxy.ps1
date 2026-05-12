# Description: Resolves SCOM "Agent Proxy not enabled" alerts by enabling proxy on the affected agents
# Requirements: Operations Manager PowerShell module (OperationsManager)
Import-Module OperationsManager

$Alerts = Get-SCOMAlert -ResolutionState 0 -Name 'Agent Proxy not enabled'

foreach ($Alert in $Alerts) {
    $sep          = $Alert.Description.IndexOf('service (')
    $ComputerName = $Alert.Description.Substring($sep + 9).Split(')')[0].Trim()
    $Agent        = Get-SCOMAgent -DNSHostName $ComputerName

    if ($Agent.ProxyingEnabled.Value -eq $false) {
        Enable-SCOMAgentProxy -Agent $Agent
        Write-Host "Proxy enabled for: $ComputerName" -ForegroundColor Green
    }
    Resolve-SCOMAlert -Alert $Alert
}
