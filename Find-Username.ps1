<#
.SYNOPSIS
    Find computers where user is currently logged it.
.DESCRIPTION
    This script will pull all computers from AD, then look for a specified
    username on each one.

.NOTES
    Version:            1.0
    Author:             Daniel Allen
    Last Modified Date: 16.08.2016
.EXAMPLE
    ./Find-Username.ps1
#>

$ErrorActionPreference = "SilentlyContinue"

$SearchBase = "OU=Computers,DC=YOUR,DC=DOMAIN,DC=NAME" # OU with computers
$Domain = "DOMAIN" # Short name, not FQDN

$Name = Read-Host "Enter username"

$Computers = Get-ADComputer -SearchBase $SearchBase -Filter * | Select -expandproperty name

ForEach ($Computer in $Computers) {
  if (Test-Connection $Computer -Count 2 -quiet) {
    $Username = (Get-WMIObject Win32_ComputerSystem -Computername $Computer).UserName
    if ($Username -eq "$Domain\$Name") { Write-Host "[FOUND] " -foregroundcolor green -nonewline; Write-Host "${Computer}: $Username" -foregroundcolor magenta }
  }
}
