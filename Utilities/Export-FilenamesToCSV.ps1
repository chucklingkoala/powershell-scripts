# Description: Lists files in a user-selected folder, parses structured filename components
#              (split on _ and .), and exports them to CSV. Useful for batch document import prep.
# Requirements: Windows.Forms assembly (included in .NET Framework)
# Adapt: Modify the filename parsing logic to match your filename convention.
[System.Reflection.Assembly]::LoadWithPartialName('System.Windows.Forms') | Out-Null

$Dialog = New-Object System.Windows.Forms.FolderBrowserDialog
$Dialog.SelectedPath  = [System.Environment]::GetFolderPath('Desktop')
$Dialog.Description   = 'Select folder containing files to index'
$Dialog.ShowDialog() | Out-Null
$FolderPath = $Dialog.SelectedPath

$Filenames  = Get-ChildItem $FolderPath | Select-Object -ExpandProperty Name
$OutputFile = Join-Path $FolderPath 'FileIndex.csv'
$Records    = [System.Collections.Generic.List[PSCustomObject]]::new()
$Count      = 0

foreach ($Filename in $Filenames) {
    # Adapt: split filename on underscore and dot to extract components
    # Example filename format: TYPE_ACCOUNTNUM_YYMMDD.ext
    $Parts = $Filename.Split('_.', [System.StringSplitOptions]::RemoveEmptyEntries)
    if ($Parts.Count -lt 4) { continue }

    $Records.Add([PSCustomObject]@{
        Filename    = $Filename
        DocType     = switch ($Parts[0]) {
                          'HS' { 'Holding Summary' }
                          'TX' { 'Distribution and Tax Statement' }
                          'FS' { 'Annual Fee Statement' }
                          default { $Parts[0] }
                      }
        AccountNum  = $Parts[1]
        FileDate    = try { Get-Date $Parts[2] -Format 'dd/MM/yyyy' } catch { $Parts[2] }
    })

    $Count++
    Write-Progress -Activity 'Indexing files' -Status "$Count / $($Filenames.Count)" -PercentComplete ($Count / $Filenames.Count * 100)
}

$Records | Export-Csv $OutputFile -NoTypeInformation
Write-Host "Exported $($Records.Count) records to $OutputFile"
