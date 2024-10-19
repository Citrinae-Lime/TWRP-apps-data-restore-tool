TWRP apps data restore tool
===========================

This tool allows you to recover apps data from a TWRP-compatible backup

## Android requirements

- TWRP
- android shell with root
- ADB enabled

## Computer requirements

- Windows with Windows Terminal
- Powershell
- (ADB)[https://developer.android.com/tools/releases/platform-tools]

## Usage

You can use the `Get-Help` command to get the usage of the script.

1. `.\0_Extract.qs1 E:\Path\to\TWRP\BACKUPS\files`
2. `$(Get-ChildItem E:\Path\to\TWRP\BACKUPS\*\data\data).BaseName | Out-File -FilePath Packages.txt`
3. Remove the unwanted/system packages from Packages.txt
4. `.\2_RestorePackages.ps1 $(Get-Content Packages.txt) -lpkg E:\Path\to\TWRP\BACKUPS\*\data\data\ -lapk E:\Path\to\TWRP\BACKUPS\*\data\app\`