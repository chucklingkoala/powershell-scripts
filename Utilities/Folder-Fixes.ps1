# Description: Utility functions for bulk NTFS permission operations using xcacls.vbs.
#              Inherit permissions, remove a user, fix permissions, or create Home/Profile folders.
# Requirements: xcacls.vbs present in C:\Windows or current directory, run as admin

function Set-InheritedPermissions {
    param([string]$Path)
    Get-ChildItem $Path | ForEach-Object {
        cscript.exe C:\Windows\xcacls.vbs $_.FullName /E /I Copy
    }
}

function Remove-UserPermissions {
    param([string]$Path, [string]$Username)
    Get-ChildItem $Path | ForEach-Object {
        cscript.exe xcacls.vbs $_.FullName /E /R $Username
    }
}

function Set-ModifyPermissions {
    param([string]$Path, [string]$DomainGroup)
    Get-ChildItem $Path | ForEach-Object {
        cscript.exe C:\Windows\xcacls.vbs $_.FullName /E /G "$DomainGroup\$_`:M"
    }
}

function New-HomeProfileFolders {
    param([string]$BasePath)
    Get-ChildItem $BasePath | ForEach-Object {
        New-Item -Name 'Home'    -ItemType Directory -Path "$BasePath\$_\" -ErrorAction SilentlyContinue | Out-Null
        New-Item -Name 'Profile' -ItemType Directory -Path "$BasePath\$_\" -ErrorAction SilentlyContinue | Out-Null
    }
}
