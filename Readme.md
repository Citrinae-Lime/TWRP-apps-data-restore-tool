TWRP apps data restore tool
===========================

This tool allows you to recover apps data from a TWRP-compatible backup

> [!WARNING]
> The Windows file system is not fully compatible with the Android file system, and this is only recommended when there is no Linux computer around.

## Android requirements

- TWRP
- android shell with root
- ADB enabled

## Computer requirements

- Windows with Windows Terminal
- Powershell
- [ADB](https://developer.android.com/tools/releases/platform-tools)

## Usage

> [!TIP]
> You can use the `Get-Help` cmdlet to get the usage of the script.

1. `.\0_Extract.qs1 E:\Path\to\TWRP\BACKUPS\files`
2. ```PowerShell
   $(Get-ChildItem E:\Path\to\TWRP\BACKUPS\*\data\data).BaseName | Out-File -FilePath Packages.txt
3. Remove the unwanted/system packages from `Packages.txt`
4. ```PowerShell
   .\2_RestorePackages.ps1 $(Get-Content Packages.txt) -lpkg E:\Path\to\TWRP\BACKUPS\*\data\data\ -lapk E:\Path\to\TWRP\BACKUPS\*\data\app\

> [!NOTE]
> You can use `Set-ExecutionPolicy` or `Unblock-File` cmdlet to allow the script to run.
