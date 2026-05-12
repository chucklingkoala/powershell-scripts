# Description: Disables password expiration for a specific Azure AD / Entra ID user
# Requirements: AzureAD module (Install-Module AzureAD) or Microsoft.Graph
# Usage: Set-DisablePasswordExpiration -UserPrincipalName 'user@domain.onmicrosoft.com'
param(
    [Parameter(Mandatory)][string]$UserPrincipalName
)

# AzureAD module version:
Set-AzureADUser -ObjectId $UserPrincipalName -PasswordPolicies DisablePasswordExpiration
Write-Host "Password expiration disabled for: $UserPrincipalName"

# Microsoft Graph equivalent (uncomment if using Graph instead of AzureAD module):
# Update-MgUser -UserId $UserPrincipalName -PasswordPolicies 'DisablePasswordExpiration'
