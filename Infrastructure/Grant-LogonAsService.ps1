# Description: Grants 'Log on as a service' and 'Log on as a batch job' rights to a domain account
#              using secedit to modify the local security policy.
# Requirements: Run as Administrator
param(
    [Parameter(Mandatory)][string]$DomainAccount,  # e.g. 'DOMAIN\ServiceAccountName'
    [string]$ComputerName = $env:COMPUTERNAME
)

$LOGON_AS_SERVICE = 'SeServiceLogonRight'
$LOGON_AS_BATCH   = 'SeBatchLogonRight'

function Grant-UserRight {
    param([string]$Account, [string]$Right, [string]$Computer)
    try {
        $SID       = ([System.Security.Principal.NTAccount]$Account).Translate([System.Security.Principal.SecurityIdentifier]).Value
        $dbPath    = Join-Path $env:TEMP 'secedt.sdb'
        $exportPath = Join-Path $env:TEMP 'secexp.inf'

        if (Test-Path $dbPath)    { Remove-Item -Force $dbPath }
        if (Test-Path $exportPath) { Remove-Item -Force $exportPath }

        secedit /export /cfg $exportPath /areas USER_RIGHTS | Out-Null
        if ($LASTEXITCODE -ne 0) { throw 'secedit export failed' }

        $lines = (Get-Content $exportPath -Raw) -split "`r`n"
        $rightFound = $false
        $newLines = foreach ($line in $lines) {
            if ($line -match "^$Right\s*=") {
                $rightFound = $true
                if ($line -notmatch [regex]::Escape($SID)) { $line += ",*$SID" }
            }
            $line
        }
        if (-not $rightFound) { $newLines += "$Right = *$SID" }

        $newLines | Set-Content $exportPath -Force
        secedit /configure /db $dbPath /cfg $exportPath /areas USER_RIGHTS | Out-Null
        if ($LASTEXITCODE -ne 0) { throw 'secedit configure failed' }

        Remove-Item $dbPath, $exportPath -Force -ErrorAction SilentlyContinue
        Write-Host "Granted $Right to $Account on $Computer" -ForegroundColor Green
    } catch {
        Write-Error "Failed to grant $Right to $Account`: $_"
    }
}

Grant-UserRight -Account $DomainAccount -Right $LOGON_AS_SERVICE -Computer $ComputerName
Grant-UserRight -Account $DomainAccount -Right $LOGON_AS_BATCH   -Computer $ComputerName
