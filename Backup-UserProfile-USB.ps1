<#
.SYNOPSIS
    Backup user files to USB Drive.
.DESCRIPTION
    This script will create a backup of user's profile folder (Usually found in C:\Users)
    as well as all non-system folders and files found in the root of C:\ Drive.
    The backup is done via robocopy utility. By defalut, it uses 16 threads (/MT:16 switch), but if you're having problems you could adjust /MT switch or remove it altogether.

.NOTES
    Version:            1.2
    Author:             Daniel Allen
    Last Modified Date: 16.08.2016
.EXAMPLE
    ./Backup-UserProfile-USB.ps1
#>

$ErrorActionPreference = "Continue"

### Import Assemblies
[Void][Reflection.Assembly]::Load("System.Windows.Forms, Version=2.0.0.0, Culture=neutral, PublicKeyToken=b77a5c561934e089")

### RegEx String to filter out system folders and files
$RegEx = "(Intel|Program\sFiles|Temp|Users|PerfLogs|Windows)|(^.*\.(bat|sys|log|tmp|bak)$)"

$Date = Get-Date -f dd.MM.yyyy-HH.mm

### Function To Display Selection Menu
function Select-TextItem {

    [CmdletBinding()]

    Param (

        [Parameter(Mandatory=$true)]
        $Options,
        $DisplayProperty
    )

    [int]$OptionPrefix = 1

    # Create Menu List
    ForEach ($Option in $Options) {

        if ($DisplayProperty -eq $null) { Write-Host ("{0,3}: {1}" -f $OptionPrefix,$Option) }

        else { Write-Host ("{0,3}: {1}" -f $OptionPrefix,$Option.$DisplayProperty) }

        $OptionPrefix++
    }

    Write-Host ("{0,3}: {1}" -f 0,"To Cancel")

    [int]$Response = Read-Host "Enter Selection"

    $Value = $null

    if ($Response -gt 0 -and $Response -le $Options.Count) { $Value = $Options[$Response-1] }

    else { Exit }

    return $Value
}

$UsbDisk = Get-WmiObject -Class Win32_DiskDrive | Where {$_.InterfaceType -eq "USB"} | ForEach-Object {Get-WmiObject -Query "ASSOCIATORS OF {Win32_DiskDrive.DeviceID=`"$($_.DeviceID.Replace('\','\\'))`"} WHERE AssocClass = Win32_DiskDriveToDiskPartition"} | ForEach-Object {Get-WmiObject -Query "ASSOCIATORS OF {Win32_DiskPartition.DeviceID=`"$($_.DeviceID)`"} WHERE AssocClass = Win32_LogicalDiskToPartition"} | ForEach-Object {$_.DeviceID}

if ($UsbDisk -eq $null) { [void][System.Windows.Forms.MessageBox]::Show("No USB Drive Found, Please Plug-In the USB Drive","USB Drive not found") }

elseif(($UsbDisk).Count -gt 1) { [void][System.Windows.Forms.MessageBox]::Show("Multiple USB Drives Found, Please Unplug Unnecessary USB Drives","Multiple USB Drives")}

else {

    Write-Host "Select Profile To Backup:" -foregroundcolor cyan

    $ProfileSelection = Select-TextItem -Options (Get-ChildItem -Path "C:\Users") -DisplayProperty Name

    $BackupFolder = $ProfileSelection.Name + "-$Date"

    ### Add current user to profile folder's Acl
    $Acl = Get-Acl $ProfileSelection.FullName
    $AccessRule = New-Object System.Security.AccessControl.FileSystemAccessRule("$env:USERNAME", "FullControl", "ContainerInherit,ObjectInherit", "None", "Allow")
    $Acl.SetAccessRule($AccessRule)
    Set-Acl $ProfileSelection.FullName $Acl

    $UserProfile = Get-ChildItem -Recurse $ProfileSelection.FullName
    $UserProfileSize = $UserProfile | Measure-Object -Property Length -Sum

    $RootFolders = Get-ChildItem -Path "C:\" | Where {$_.PSIsContainer -and $_.Name -notmatch $RegEx}
    $RootFoldersSize = $RootFolders | Get-ChildItem -Recurse | Measure-Object -Property Length -Sum

    $RootFiles = Get-ChildItem -Path "C:\" | Where {! $_.PSIsContainer -and $_.Name -notmatch $RegEx}
    $RootFilesSize = $RootFiles | Measure-Object -Property Length -Sum

    [int]$DataFileSize = ($UserProfileSize.Sum + $RootFoldersSize.Sum + $RootFilesSize.Sum)

    $FreeSpace = (Get-WmiObject -Class Win32_LogicalDisk | Where {$_.DeviceID -eq $UsbDisk}).FreeSpace

    if ($DataFileSize -gt $FreeSpace) { [void][System.Windows.Forms.MessageBox]::Show("Your $UsbDisk Drive doesn't have enough space.","Not Enough Space") }

    ### Backup
    else {

        New-Item -Path $UsbDisk\$BackupFolder -ItemType Directory -Force | Out-Null

        $UserProfilePath = $ProfileSelection.FullName
        $UserProfileFolder = $ProfileSelection.Name

        Robocopy $UserProfilePath "$UsbDisk\$BackupFolder\$UserProfileFolder" /XJ /MIR /MT:16 /r:0 /A-:SH

        if ($RootFolders -ne $null) {

           ForEach($Folder in $RootFolders) {

               $FolderName = $Folder.Name
               $FolderFullName = $Folder.FullName

               Robocopy $FolderFullName "$UsbDisk\$BackupFolder\Root\$FolderName" /XJ /MIR /MT:16 /r:0 /A-:SH
           }
        }

        if ($RootFiles -ne $null) {

            ForEach($File in $RootFiles) {

                $FileName = $File.Name

                Robocopy "C:\" "$UsbDisk\$BackupFolder\Root\" $FileName /XJ /MT:16 /r:0 /A-:SH
            }
        }

        Write-Host "`nCompleted!" -foregroundcolor cyan

        [void][System.Windows.Forms.MessageBox]::Show("Backup completed successfully.","Finished")

        explorer "$UsbDisk\$BackupFolder"
    }
}
