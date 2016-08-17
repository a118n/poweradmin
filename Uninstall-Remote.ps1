<#
.SYNOPSIS
  Uninstall software from remote PC
.DESCRIPTION
  This script will uninstal any MSI-based software from a remote computer.
  Doesn't work with software that uses custom uninstallers (TeamViewer, Dropbox, etc).
.NOTES
  Version:            1.0
  Author:             Daniel Allen
  Last Modified Date: 16.08.2016
.EXAMPLE
  ./Uninstall-Remote.ps1
#>

$ErrorActionPreference = "Continue"

$Computer = Read-Host "Enter PC Name"

$SoftwareName = Read-Host "Enter Software To Uninstall"

if (Test-Connection $Computer -Count 2 -quiet) {

    #Start remote registry service
    Get-Service -Name RemoteRegistry -ComputerName $Computer | Set-Service -Status Running

    $array = @()

    $UninstallKey="SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Uninstall"
    $reg=[microsoft.win32.registrykey]::OpenRemoteBaseKey('LocalMachine',$Computer)
    $regkey=$reg.OpenSubKey($UninstallKey)
    $subkeys=$regkey.GetSubKeyNames()

    ForEach($key in $subkeys) {
      $thisKey=$UninstallKey+"\\"+$key
      $thisSubKey=$reg.OpenSubKey($thisKey)
      $obj = New-Object PSObject
      $obj | Add-Member -MemberType NoteProperty -Name "DisplayName" -Value $($thisSubKey.GetValue("DisplayName"))
      $obj | Add-Member -MemberType NoteProperty -Name "DisplayVersion" -Value $($thisSubKey.GetValue("DisplayVersion"))
      $obj | Add-Member -MemberType NoteProperty -Name "UninstallString" -Value $($thisSubKey.GetValue("UninstallString"))
      $array += $obj
    }

    # if OS is 64-bit, do the same above for 64-bit node
    $Arch = Get-WmiObject win32_operatingsystem -Computer $Computer | ForEach { $_.OSArchitecture }

    if ($Arch -eq "64-bit") {

      $UninstallKey="SOFTWARE\\Wow6432Node\\Microsoft\\Windows\\CurrentVersion\\Uninstall"
      $reg=[microsoft.win32.registrykey]::OpenRemoteBaseKey('LocalMachine',$Computer)
      $regkey=$reg.OpenSubKey($UninstallKey)
      $subkeys=$regkey.GetSubKeyNames()

      ForEach($key in $subkeys) {
          $thisKey=$UninstallKey+"\\"+$key
          $thisSubKey=$reg.OpenSubKey($thisKey)
          $obj = New-Object PSObject
          $obj | Add-Member -MemberType NoteProperty -Name "DisplayName" -Value $($thisSubKey.GetValue("DisplayName"))
          $obj | Add-Member -MemberType NoteProperty -Name "DisplayVersion" -Value $($thisSubKey.GetValue("DisplayVersion"))
          $obj | Add-Member -MemberType NoteProperty -Name "UninstallString" -Value $($thisSubKey.GetValue("UninstallString"))
          $array += $obj
      }
    }

    $UninstallStrings = $array | Where { $_.DisplayName -like "*$SoftwareName*" } | ForEach { $_.UninstallString } | Out-String -stream

    ForEach ($String in $UninstallStrings) {

        if ($String -Match "/I") {

            $String = $String.Replace("/I", "/X")
        }

        $CmdArgs = "$String /quiet /norestart"

        Write-Host "Uninstalling " -nonewline -foregroundcolor cyan; Write-Host "$SoftwareName" -nonewline -foregroundcolor magenta; Write-Host " from: " -nonewline -foregroundcolor cyan; Write-Host "$Computer" -foregroundcolor magenta

        $Proc = Invoke-WmiMethod -class Win32_process -name Create -ArgumentList $CmdArgs -ComputerName $Computer

        # Wait for previous uninstall to finish
        do { Get-Process -id $Proc.ProcessId -ComputerName $Computer -ea SilentlyContinue | Out-Null } while ($?)
    }
}

else { Write-Host "Computer seems to be offline" -foregroundcolor red }
