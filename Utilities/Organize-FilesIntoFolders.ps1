# Description: Moves each loose file in the current directory into its own subfolder
#              named after the file (without extension). Run from the folder containing the files.
$FileList = Get-ChildItem -File
foreach ($File in $FileList) {
    $FolderName = [IO.Path]::GetFileNameWithoutExtension($File.FullName)
    New-Item $FolderName -ItemType Directory -ErrorAction SilentlyContinue | Out-Null
    Move-Item $File.FullName -Destination "$FolderName\"
}
