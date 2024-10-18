<#
  .SYNOPSIS
  Extract backup files.
  .DESCRIPTION
  Use windows built-in tar.exe to extract the backup file created by twrp.
  .PARAMETER BackupFolder
  Path to the backup folder.
  Like "E:\TWRP\BACKUPS\*\*\"
  .EXAMPLE
  .\0_Extract.ps1 "E:\TWRP\BACKUPS\random\backup\"
#>
[CmdletBinding()]
Param([Parameter(Mandatory=$True)][ValidateNotNullOrEmpty()][String]$BackupFolder)
Set-Location $BackupFolder
foreach ($file in Get-ChildItem data.*.win???){tar.exe -xvf $file}