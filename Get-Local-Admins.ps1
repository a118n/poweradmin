<#
.SYNOPSIS
    Find local admins on a computers.
.DESCRIPTION
    This script will pull all computers from AD, then look for users and groups which have local admin rights.
    By default it excludes built-in Administrator account and "Domain Admins" group.

.NOTES
    Version:            1.0
    Author:             Daniel Allen
    Last Modified Date: 16.08.2016
.EXAMPLE
    ./Get-Local-Admins.ps1
#>

$ErrorActionPreference = "Continue"

$OU = "OU=Computers,DC=YOUR,DC=DOMAIN,DC=NAME" # OU with computers

function RetrieveAdmins($Computer) {

  $List = Get-WmiObject -ComputerName $Computer -Query "select * from win32_groupuser where GroupComponent=""Win32_Group.Domain='$Computer',Name='Administrators'""" | ForEach-Object { $_.PartComponent }

  ForEach ($Item in $List) { $Item.Split(",")[1].TrimStart('Name="').TrimEnd('"') }
}

$Counter = 0

$Computers = Get-ADComputer -SearchBase $OU -Filter * | ForEach-Object { $_.Name } | Sort

$Array = @()

ForEach ($Computer in $Computers) {

  $Counter++

  Write-Progress -Activity "[Processing $Counter of $($Computers.Count)]" -Status "Querying $($Computer)" -PercentComplete (($Counter/$Computers.Count) * 100) -CurrentOperation "$([math]::Round(($Counter/$Computers.Count) * 100))% complete"

  if (Test-Connection -ComputerName $Computer -Count 2 -Quiet) {

    $Obj = New-Object PSObject
    $Obj | Add-Member -MemberType NoteProperty -Name "Computer" -Value $Computer

    $LocalAdmins = RetrieveAdmins($Computer) | Where { $_ -ne "Domain Admins" -and $_ -ne "Administrator" }

    if ($LocalAdmins) {

      $Obj | Add-Member -MemberType NoteProperty -Name "Local Admins" -Value $([string]::Join(", ",$LocalAdmins))

      Write-Host "Local Admins on " -nonewline; Write-Host "${Computer}:`n" -foregroundcolor yellow

      $LocalAdmins

      Write-Host "`n`------------------------------------"
    }

    else { $Obj | Add-Member -MemberType NoteProperty -Name "Local Admins" -Value "" }

    $Array += $Obj
  }
}

$Array | Format-Table -AutoSize

$Array | Export-CSV -Path "Get-Local-Admins.csv" -NoTypeInformation

Write-Host "`nDone. Get-Local-Admins.csv placed in current dir.`n" -foregroundcolor green
