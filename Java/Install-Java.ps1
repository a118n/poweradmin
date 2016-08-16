<#
.SYNOPSIS
    Install Java on a remote computer.
.DESCRIPTION
    This script will detect all installed versions of Java, delete outdated ones, then install the most recent one on a remote computer.
    It also will deploy configuration settings and disable auto-update.
    It's generally advised to check afterwards if everything was installed correctly.
    Do not forget to adjust config files in Deployment directory.

.NOTES
    Version:            1.2
    Author:             Daniel Allen
    Last Modified Date: 16.08.2016
.EXAMPLE
    ./Install-Java.ps1
#>

$ErrorActionPreference = "Continue"

# Adjust these variables according to where you put these files
# Normally you would want to put them on a server share
# Invoke-WmiMethod doesn't understand relative paths, so you have to specify full paths in $Exe and $AUReg variables
$Exe = "jre-latest.exe"
$AUReg = "Deployment\DisableAutoUpdate.reg"
$InstallString = "$Exe /s SPONSORS=0"
$DeploymentSettings = "Deployment\deployment*"
# This file is initially empty, for auto-updater below to dowload latest java
$CurrentURL = "current_url.txt"

# Check if there's a newer version available. If current_url.txt is empty, will download latest java
# Works only in Powershell 3 and higher
if ((Get-Host).Version.Major -ge 3) {

    Write-Host "Checking for updates..." -foregroundcolor Yellow

    # Get current download link
    $URL = (Invoke-WebRequest -Uri 'http://www.java.com/en/download/manual.jsp').Links | Where-Object { $_.innerHTML -eq "Windows Offline" } | Select-Object -ExpandProperty href

    if ($URL -eq (Get-Content $CurrentURL)) { Write-Host "No new version is available, proceeding to install" -foregroundcolor Green }

    elseif ($URL -eq $null) { Write-Host "Failed to check for updates, URL is empty. Make sure your internet is working." -foregroundcolor red }

    else {

        Write-Host "Downloading new version..." -foregroundcolor yellow
        Invoke-WebRequest $URL -OutFile $Exe
        $Url > $CurrentURL
    }
}

# Get actual version from file
$ActualVersion = (Get-Item $Exe).VersionInfo.FileVersion

$Computer = Read-Host "Enter Target Hostname"

if (Test-Connection $Computer -quiet) {

    Write-Host "Looking for installed Java versions, please wait..." -foregroundcolor yellow

    # Query Installed Java

    # Start remote registry service
    Get-Service -Name RemoteRegistry -ComputerName $Computer | Set-Service -Status Running

    # Create array to store data from registry
    $Array = @()

    # Define the variable to hold the location of Currently Installed Programs
    $UninstallKey="SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Uninstall"

    # Create an instance of the Registry Object and open the HKLM base key
    $Reg=[microsoft.win32.registrykey]::OpenRemoteBaseKey('LocalMachine',$Computer)

    # Drill down into the Uninstall key using the OpenSubKey Method
    $RegKey=$Reg.OpenSubKey($UninstallKey)

    # Retrieve an array of string that contain all the subkey names
    $SubKeys=$RegKey.GetSubKeyNames()

    # Open each Subkey and use GetValue Method to return the required values for each
    ForEach($Key in $SubKeys) {
        $ThisKey=$UninstallKey+"\\"+$Key
        $ThisSubKey=$Reg.OpenSubKey($ThisKey)
        $Obj = New-Object PSObject
        $Obj | Add-Member -MemberType NoteProperty -Name "DisplayName" -Value $($ThisSubKey.GetValue("DisplayName"))
        $Obj | Add-Member -MemberType NoteProperty -Name "DisplayVersion" -Value $($ThisSubKey.GetValue("DisplayVersion"))
        $Obj | Add-Member -MemberType NoteProperty -Name "UninstallString" -Value $($ThisSubKey.GetValue("UninstallString"))
        $Array += $Obj
    }

    $JavaVersion = $Array | Where { $_.DisplayName -like "*Java*" -and $_.DisplayName -notlike "*Updater*" } | ForEach { $_.DisplayVersion } | Out-String -stream

    if ($JavaVersion -eq $ActualVersion -and $JavaVersion.Count -eq "1") { Write-Host "Java is up to date." -foregroundcolor green }

    else {

        if ($JavaVersion.Count -ne "0") {

            Write-Host "Removing old Java versions..." -foregroundcolor yellow

            # Remove old versions

            $JavaVer = $Array | Where { $_.DisplayName -like "*Java*" } | ForEach { $_.UninstallString } | Out-String -stream

            ForEach ($Ver in $JavaVer) {

                if ($Ver -Match "/I") { $Ver = $Ver.Replace("/I", "/X") }

                $CmdArgs = "$Ver /quiet /norestart"

                $Proc = Invoke-WmiMethod -class Win32_process -name Create -ArgumentList $CmdArgs -ComputerName $Computer

                # Wait for previous uninstall to finish
                do { Get-Process -id $Proc.ProcessId -ComputerName $Computer -ea SilentlyContinue | Out-Null } while ($?)
            }

            Start-Sleep -s 20
        }
    }

    if ($JavaVersion -NotContains $ActualVersion -or $JavaVersion.Count -eq "0") {

        # Kill all Internet Explorer Processes, might conflict with installation
        $ieprocs = Get-WmiObject -Class Win32_Process -ComputerName "$Computer" -Filter {name="iexplore.exe"}

        if ($ieprocs) {

            ForEach ($ieproc in $ieprocs) { $ieproc.Terminate() | Out-Null }
        }

        Write-Host "Installing Java..." -foregroundcolor yellow
        Write-Host "
           ))
          (((
        +-----+
        |     |]
        '-----' " -foregroundcolor green

        # Install
        $Proc2 = Invoke-WmiMethod -class Win32_process -name Create -ArgumentList $InstallString -ComputerName $Computer

        do { Get-Process -id $Proc2.ProcessId -ComputerName $Computer -ea SilentlyContinue | Out-Null } while ($?)

    }

    # Copy Deployment Settings
    Write-Host "Copying deployment settings..." -foregroundcolor yellow

    if (-Not (Test-Path "\\$Computer\c$\Windows\Sun\Java\Deployment")) {

        New-Item -Path "\\$Computer\c$\Windows\Sun\Java\Deployment" -itemtype Directory -force | Out-Null
    }

    Copy-Item -Path $DeploymentSettings -Destination "\\$Computer\c$\Windows\Sun\Java\Deployment\" -force | Out-Null

    # Disable Auto-Update
    $DisableAU = "regedit /i /s $AUReg"
    Invoke-WmiMethod -class Win32_process -name Create -ArgumentList $DisableAU -ComputerName $Computer | Out-Null

    # Cleanup
    if (Test-Path "\\$Computer\c$\Oracle") { Remove-Item -Path "\\$Computer\c$\Oracle" -Recurse -Force | Out-Null }
    if (Test-Path "\\$Computer\c$\.oracle_jre_usage") { Remove-Item -Path "\\$Computer\c$\.oracle_jre_usage" -Recurse -Force | Out-Null }

    Write-Host "All Done. Enjoy your day =^..^=" -foregroundcolor green
}

else { Write-Host "Computer seems to be offline" -foregroundcolor red }
