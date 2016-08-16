<#
.SYNOPSIS
  Get log on and log off dates from a particular computer.
.DESCRIPTION
  This script will search for log on and log off events on a particular computer
  and display them in a table.
.NOTES
  Version:            1.0
  Author:             Daniel Allen
  Last Modified Date: 16.08.2016
.EXAMPLE
  ./Get-LogOn-LogOff.ps1
#>

Param (
  [string]$Computer = (Read-Host Remote computer name),
  [int]$Days = 30
)

$Result = @()

Write-Host "Gathering Event Logs, this can take awhile..."

$ELogs = Get-EventLog System -Source Microsoft-Windows-WinLogon -After (Get-Date).AddDays(-$Days) -ComputerName $Computer

if ($ELogs) {

  Write-Host "Processing..."

  ForEach ($Log in $ELogs) {

    if ($Log.InstanceId -eq 7001) { $ET = "Logon" }

    elseif ($Log.InstanceId -eq 7002) { $ET = "Logoff" }

    else { Continue }

    $Result += New-Object PSObject -Property @{
     Time = $Log.TimeWritten
     'Event Type' = $ET
     User = (New-Object System.Security.Principal.SecurityIdentifier $Log.ReplacementStrings[1]).Translate([System.Security.Principal.NTAccount])
    }
  }

  $Result | Select Time,"Event Type",User | Sort Time -Descending | Out-GridView

  Write-Host "Done."
}

else {

  Write-Host "Problem with $Computer."
  Write-Host "If you see a 'Network Path not found' error, try starting the Remote Registry service on that computer."
  Write-Host "Or there are no logon/logoff events (XP requires auditing be turned on)"
}
