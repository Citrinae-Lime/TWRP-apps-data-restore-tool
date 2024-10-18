# The following script will restore apps 
# from a TWRP backup to an android phone.
# Root adb access must be available.

# 1. Extract all the data volumes in the TWRP backup
    # tar.exe -xvf data.ext4.win000
    # tar.exe -xvf data.ext4.win001 etc.
# 2. Turn the bash script into an executable 
    # chmod +x restore_android_packages.sh
# 3. Run script
    # ./restore_android_packages.

# The following resources were used in the creation of this script.
# https://www.semipol.de/2016/07/30/android-restoring-apps-from-twrp-backup.html
# https://itsfoss.com/fix-error-insufficient-permissions-device/

[CmdletBinding()]
param (
    [Parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()][object]$pkgList
)

# TWRP extract location for data/data/
# Change if necessary!
$localpackages = "$env:USERPROFILE\data\data\"
$localapkpath = "$env:USERPROFILE\data\app" # do not append '/'
# Android delivery destination
$remotepackages = "/data/data/"
$temppackages = "/sdcard/tmp/"

Write-Host "========================================================="
# Write-Host "Killing ADB server"
# .\adb.exe kill-server
# Write-Host "Starting ADB server with sudo"
# Start-Process -NoNewWindow -Wait "powershell" -ArgumentList "Start-Process -NoNewWindow -Wait -Verb runAs -ArgumentList 'adb start-server'"
Write-Host "Starting ADB as root"
.\adb.exe shell su -c whoami
# Write-Host "========================================================="

function Restore-Package {
    param (
        [string]$package
    )

    if (-not $package) {
        return
    }

    Write-Host "========================================================="

    .\adb.exe shell pm path $package
    $exists = $LASTEXITCODE

    # Userinstalled Apps
    if ($exists -eq 0) {
        Write-Host "Killing $package"
        .\adb.exe shell am force-stop $package
        Write-Host "Clearing $package"
        .\adb.exe shell pm clear $package
    }

    Write-Host "Reinstalling apk of $package"
    .\adb.exe install-multiple -r $(Get-ChildItem -Path "$localapkpath\*\$package-*\*.apk").FullName
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Failed to install $apk" -ForegroundColor Red
        return
    }

    # Preinstalled Apps
    # if ($exists -ne 0) {
    #     Write-Host "Failed to find preinstalled $apk" -ForegroundColor DarkYellow
    #     return
    # }
    # Write-Host "Killing $package"
    # .\adb.exe shell am force-stop $package
    # Write-Host "Clearing $package"
    # .\adb.exe shell pm clear $package

    Write-Host "Restoring $package"
    # Remove-Item -Path "$localpackages$package\cache" -Recurse
    # Remove-Item -Path "$localpackages$package\code_cache" -Recurse
    .\adb.exe push "$localpackages$package" "$temppackages$package"
    .\adb.exe shell su -c cp -r "$temppackages$package" "$remotepackages"
    Write-Host "Correcting package"
    $userid = .\adb.exe shell dumpsys package $package | Select-String "userId" | ForEach-Object { $_.Line.Split('=')[1].Trim() }
    .\adb.exe shell su -c chown -R "$userid`:$userid" "$remotepackages$package"
    .\adb.exe shell su -c restorecon -Rv "$remotepackages$package"
    Write-Host "Package restored on device." -ForegroundColor Green
    .\adb.exe shell rm -rf "$temppackages$package"
}

ForEach($pkg in $pkgList) {
    Restore-Package $pkg
    Start-Sleep -Seconds 1
}