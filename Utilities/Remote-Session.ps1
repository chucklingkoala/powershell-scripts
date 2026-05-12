# Description: Prompts for a computer name via an input box and opens a remote PowerShell session
# Requirements: PowerShell remoting enabled on the target server, Microsoft.VisualBasic assembly
$Cred   = Get-Credential -Message 'Enter credentials for remote session'
[System.Reflection.Assembly]::LoadWithPartialName('Microsoft.VisualBasic') | Out-Null
$Server = [Microsoft.VisualBasic.Interaction]::InputBox('Enter the computer name or FQDN', 'Remote Session', 'server.domain.local')
if ($Server) {
    $PSS = New-PSSession $Server -Credential $Cred
    Enter-PSSession $PSS
}
