# Description: Reads a CSV of tape barcodes and removes all recovery points from each tape in DPM,
#              freeing the tapes for reuse.
# Requirements: DPM PowerShell module, CSV with a 'tapes' column containing barcodes
# WARNING: This permanently deletes recovery points. Ensure tapes are no longer needed before running.
param(
    [string]$CSVPath   = 'C:\Scripts\Tapes.csv',
    [string]$DPMServer = 'dpm-server.domain.local'
)

$DPMLib = Get-DPMLibrary -DPMServerName $DPMServer

Import-Csv $CSVPath | ForEach-Object {
    $Barcode = $_.tapes
    $Tape    = Get-Tape -DPMLibrary $DPMLib | Where-Object { $_.Barcode.Value -eq $Barcode }

    if ($Tape) {
        $RecoveryPoints = @(Get-RecoveryPoint -Tape $Tape)
        foreach ($RP in $RecoveryPoints) {
            Remove-RecoveryPoint -RecoveryPoint $RP -ForceDeletion -Confirm:$false
        }
        Write-Host "Cleared tape: $Barcode ($($RecoveryPoints.Count) recovery points removed)" -ForegroundColor Yellow
    } else {
        Write-Warning "Tape not found in library: $Barcode"
    }
}
