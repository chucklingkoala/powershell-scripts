# Description: Exports recoverable (soft-deleted) email items from a mailbox to CSV for the past N days
# Requirements: Exchange Management Shell, Mailbox Import Export management role
#   Assign role: New-ManagementRoleAssignment -Role 'Mailbox Import Export' -User 'admin@domain.local'
param(
    [Parameter(Mandatory)][string]$MailboxAddress,
    [int]$DaysBack    = 5,
    [string]$OutputCSV = 'C:\Temp\RecoverableItems.csv'
)

Add-PSSnapin Microsoft.Exchange.Management.PowerShell.SnapIn -ErrorAction SilentlyContinue

Get-RecoverableItems -Identity $MailboxAddress `
                     -FilterItemType IPM.Note `
                     -FilterStartTime (Get-Date).AddDays(-$DaysBack) |
    Export-Csv $OutputCSV -NoTypeInformation

Write-Host "Exported to $OutputCSV"
