# Description: Sets each AD user's Department attribute to the name of their departmental group
# Requirements: Quest ActiveRoles AD Management snapin (or replace with native AD module equivalents)
# Note: Get-QADGroup / Set-QADUser are Quest cmdlets. For environments without Quest tools,
#       replace with Get-ADGroup / Get-ADGroupMember / Set-ADUser from the ActiveDirectory module.
param(
    [string]$DepartmentGroupOU = 'domain.local/AD Groups/Departmental Groups'
)

$DepartGroups = Get-QADGroup -SearchRoot $DepartmentGroupOU
$DepartGroups | ForEach-Object {
    $DepartName = (Get-QADGroup $_).Name
    Get-QADGroupMember $_ | ForEach-Object {
        Set-QADUser $_ -Department $DepartName
    }
}
