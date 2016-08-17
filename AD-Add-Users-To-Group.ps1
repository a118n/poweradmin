<#
.SYNOPSIS
    Add multiple users to a particular group.
.DESCRIPTION
    This script add users from CSV file with SamAccountNames to the target group.
    Make sure CSV header (1st line) is SamAccountName.
.NOTES
    Version:            1.0
    Author:             Danil Allen
    Last Modified Date: 31.03.2015
.EXAMPLE
    ./AD-Add-Users-To-Group.ps1
#>

Import-Module ActiveDirectory

$ErrorActionPreference = "Continue"

# Point this to your csv file
$Filename = "userlist.csv"

$Group = Read-Host "Enter the name of the group"

if ((Test-Path $Filename) -and ((Get-Item $Filename).length -gt 0kb)) {

  $Userlist = Import-Csv -Path $Filename | ForEach {$_.SamAccountName}

  ForEach ($User in $Userlist) {

      Add-ADGroupMember $Group -Members $User

      Write-Host "User " -nonewline -foregroundcolor green; Write-Host $User -nonewline -foregroundcolor cyan; Write-Host " has been added to the following group: " -nonewline -foregroundcolor green; Write-Host $Group -foregroundcolor cyan
  }

  Write-Host "All done" -foregroundcolor green
}

else { Write-Host "CSV file is empty or not found" -foregroundcolor red }
