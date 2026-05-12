# Description: Parses an application log file for status lines matching specific patterns,
#              extracts items with a given status (e.g. NOT FOUND, ACTIVE), and reports failures.
# Requirements: Access to the log file path
param(
    [string]$LogFile       = 'C:\App\Logs\status.log',
    [string[]]$StatusTerms = @('NOT FOUND', 'ACTIVE', 'ERROR')
)

$Log       = Get-Content $LogFile
$Matches   = $Log | Where-Object { $_ -match ($StatusTerms -join '|') }
$Failures  = $Matches | Where-Object { $_ -match 'NOT FOUND' }

foreach ($Item in $Failures) {
    $Parts    = $Item.Split(':')
    $ItemName = $Parts[0].Trim()
    Write-Host "$ItemName is not running or not found" -ForegroundColor Red
}

if (-not $Failures) {
    Write-Host 'All status checks passed.' -ForegroundColor Green
}
