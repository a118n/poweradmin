<#
.SYNOPSIS
  Get list of inactive computers.
.DESCRIPTION
  This script will query AD for a list of all computers which been inactive for $DaysInactive days.
.NOTES
  Version:            1.0
  Author:             Daniel Allen
  Last Modified Date: 16.08.2016
.EXAMPLE
  ./Get-Inactive-Computers.ps1
#>

$OU = "OU=Computers,DC=YOUR,DC=DOMAIN,DC=NAME" # OU with computers
$DaysInactive = 90
$Time = (Get-Date).AddDays(-($DaysInactive))

Get-ADComputer -SearchBase $OU -Filter {LastLogonTimeStamp -lt $Time} -Properties LastLogonTimeStamp | Select-Object Name,@{Name="LastLogonTimeStamp"; Expression={[DateTime]::FromFileTime($_.lastLogonTimestamp)}}
