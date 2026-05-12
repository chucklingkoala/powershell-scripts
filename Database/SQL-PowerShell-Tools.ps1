# Description: Reusable SQL Server connection and query patterns for PowerShell scripts
# Requirements: SQL Server, integrated Windows authentication or supply connection string
# Usage: Dot-source this file to get the helper functions, or copy the snippets you need.

# --- Pattern 1: Basic SqlClient connection and INSERT ---
function Invoke-SQLInsert {
    param(
        [string]$SQLServer   = 'sqlserver.domain.local',
        [string]$Database    = 'YourDatabase',
        [string]$InsertQuery
    )
    $Conn = New-Object System.Data.SqlClient.SqlConnection("Server=$SQLServer;Database=$Database;Integrated Security=True;Connect Timeout=0")
    $Conn.Open()
    $Cmd              = $Conn.CreateCommand()
    $Cmd.CommandText  = $InsertQuery
    $Cmd.ExecuteNonQuery() | Out-Null
    $Conn.Close()
}

# --- Pattern 2: Query and return a DataTable ---
function Get-SQLTable {
    param(
        [string]$SQLServer = 'sqlserver.domain.local',
        [string]$Database  = 'YourDatabase',
        [string]$Query     = 'SELECT * FROM YourTable'
    )
    $Conn = New-Object System.Data.SqlClient.SqlConnection("Server=$SQLServer;Database=$Database;Integrated Security=True;Connect Timeout=0")
    $Cmd  = $Conn.CreateCommand(); $Cmd.CommandText = $Query
    $DA   = New-Object System.Data.SqlClient.SqlDataAdapter $Cmd
    $DT   = New-Object System.Data.DataTable
    $DA.Fill($DT)
    $Conn.Close()
    return $DT
}

# --- Usage examples ---
<#
# Insert a row
Invoke-SQLInsert -SQLServer 'sqlserver.domain.local' -Database 'MyDB' -InsertQuery "INSERT MyTable VALUES ('value1', 'value2')"

# Query a table
$Rows = Get-SQLTable -SQLServer 'sqlserver.domain.local' -Database 'MyDB' -Query 'SELECT * FROM MyTable WHERE Active = 1'
$Rows | Format-Table

# Pipe data to Out-SQL (see Out-SQL.ps1)
Get-Process | Out-Sql -SqlServer 'sqlserver.domain.local' -Database 'Scratch' -Table 'Processes' -DropExisting $true
#>
