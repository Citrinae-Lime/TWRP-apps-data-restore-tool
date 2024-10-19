<#
  .SYNOPSIS
  Restore apps data from a data folder to an android phone.

  .DESCRIPTION
  The following script will restore apps from a TWRP backup to an android phone.
  Root adb access or shell with root privileges must be available.

  .PARAMETER pkgList
  A list of package that need restore.

  .PARAMETER LocalPackages
  Path to local data\data folder

  .PARAMETER LocalApkPath
  Path to local data\app folder

  .PARAMETER NoReinstall
  If specified, the script will not reinstall the APKs of the packages.

  .EXAMPLE
  .\2_RestorePackages.ps1 $(Get-Content Packages.txt) -lpkg E:\Path\to\TWRP\BACKUPS\*\data\data\ -lapk E:\Path\to\TWRP\BACKUPS\*\data\app\

  .EXAMPLE
  .\2_RestorePackages.ps1 "com.test.app","com.other.app" -NoReinstall
#>

[CmdletBinding()]
Param (
    [Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()][object]$pkgList,
    # TWRP extract location, change if necessary!
    [Parameter(Mandatory=$False)][ValidateNotNullOrEmpty()][Alias("lpkg")][String]$LocalPackages = ".\data\data\",
    [Parameter(Mandatory=$False)][ValidateNotNullOrEmpty()][Alias("lapk")][String]$LocalApkPath = ".\data\app\",
    [Parameter(Mandatory=$False)][Switch]$NoReinstall
)

# Android delivery destination
$RemotePackages = "/data/data/"
$TempPackages = "/sdcard/tmp/"

# Clear-Host
Write-Host "========================================================="
where.exe adb.exe
if ($LASTEXITCODE = 1) {
    Write-Host "Could not find adb.exe"
    exit $LASTEXITCODE
}
.\adb.exe kill-server
.\adb.exe start-server
Write-Host "Checking ADB as root"
.\adb.exe root
if ($(.\adb.exe shell id -u) -ne 0) {
    if ($(.\adb.exe shell su -c whoami) -eq "root") {$libsu="su -c"}
    else {
        Write-Host "Didn't get root permissions! Can't restore." -ForegroundColor Red
        Write-Host "You can chose one of the following two ways to be able to restore:"
        Write-Host " - Install a modded adbd version on your device"
        Write-Host " - Root your device and allow root access for 'Shell' package"
    }
}
function AdbShell {param([Parameter(Mandatory=$true)][string]$Command).\adb.exe shell $libsu $Command}
# Write-Host "========================================================="

function Restore-Package {
    param ([Parameter(Mandatory=$true)][string]$package)
    Write-Host "========================================================="

    AdbShell "pm path $package"
    $exists = $LASTEXITCODE

    if ($exists -eq 0) {
        Write-Host "Killing $package"
        AdbShell "am force-stop $package"
        Write-Host "Clearing $package"
        AdbShell "pm clear $package"
    } elseif ($NoReinstall) {
        Write-Host "Failed to find preinstalled $package" -ForegroundColor Red
        return
    }

    if (-not $NoReinstall) {
        Write-Host "Reinstalling apk of $package"
        .\adb.exe install-multiple -r $(Get-ChildItem -Path "$LocalApkPath\*\$package-*\*.apk").FullName
        if ($LASTEXITCODE -ne 0) {
            Write-Host "Failed to install $package" -ForegroundColor Red
            return
        }
    }

    # Remove cache and compress to save tame
    Write-Host "Compressing $package"
    # Remove-Item -Path "$LocalPackages$package\cache" -Recurse
    Remove-Item -Path "$LocalPackages$package\code_cache" -Recurse
    tar.exe -czf "$package.tgz" --exclude "cache" -C $LocalPackages $package

    Write-Host "Copying $package"
    .\adb.exe push "$package.tgz" "$TempPackages/$package.tgz"
    # $userid=AdbShell "stat -c '%U' $RemotePackages$package"
    # $groupid=AdbShell "stat -c '%G' $RemotePackages$package"
    $userid = AdbShell "dumpsys package $package" | Select-String "userId" | ForEach-Object { $_.Line.Split('=')[1].Trim() }

    Write-Host "Restoring $package"
    AdbShell "tar xfz $TempPackages$package.tgz -C $RemotePackages && rm $TempPackages$package.tgz"
    # AdbShell cp -r "$TempPackages$package" "$RemotePackages"

    Write-Host "Correcting package"
    AdbShell chown -R "$userid`:$userid" "$RemotePackages$package"
    # AdbShell "chown -R $userid`:$groupid $RemotePackages$package"
    AdbShell "restorecon -Rv $RemotePackages$package"

    Write-Host "Package restored on device." -ForegroundColor Green
    # AdbShell rm -rf "$TempPackages$package"
}

ForEach($package in $pkgList) {
    Restore-Package $package
    Start-Sleep -Seconds 1
}