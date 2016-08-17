<#
.SYNOPSIS
    Switch one AD group for another.
.DESCRIPTION
    This script will remove users from SourceGroup and add to TargetGroup.
.NOTES
    Version:            1.0
    Author:             Daniel Allen
    Last Modified Date: 16.08.2016
.EXAMPLE
    ./AD-Switch-Group.ps1
#>

Import-Module ActiveDirectory

$SearchBase = "OU=Users,DC=YOUR,DC=DOMAIN,DC=NAME" # OU with users

$SourceGroup = Read-Host "Enter Source Group"
$TargetGroup = Read-Host "Enter Target Group"

$SourceGroupDN = (Get-ADGroup -Identity $SourceGroup).DistinguishedName

$Userlist = Get-ADUser -SearchBase $SearchBase -filter {Enabled -eq $true -and MemberOf -eq $SourceGroupDN} | ForEach-Object {$_.SamAccountName}

ForEach ($User in $Userlist) {

    Remove-ADPrincipalGroupMembership -Identity $User -MemberOf $SourceGroup -Confirm:$false

    Write-Host "`nRemoved user " -nonewline -foregroundcolor cyan; Write-Host "$User" -nonewline -foregroundcolor magenta; Write-Host " from the group: " -nonewline -foregroundcolor cyan; Write-Host "$SourceGroup`n" -foregroundcolor magenta

    Add-ADGroupMember $TargetGroup -Members $User

    Write-Host "`nAdded user " -nonewline -foregroundcolor cyan; Write-Host "$User" -nonewline -foregroundcolor magenta; Write-Host " to the group: " -nonewline -foregroundcolor cyan; Write-Host "$TargetGroup`n" -foregroundcolor magenta
}
