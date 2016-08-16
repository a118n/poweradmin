<#
.SYNOPSIS
    Connect home drives.
.DESCRIPTION
    This script will look for AD users with empty HomeDirectory attributes, create home folders and connect them as H: drive.
.NOTES
    Version:            1.0
    Author:             Daniel Allen
    Last Modified Date: 16.08.2016
.EXAMPLE
    ./AD-Connect-HomeDrives.ps1
#>

Import-Module ActiveDirectory

# Adjust these according to your enterprise
$Domain = "DOMAIN" # Short name, not FQDN
$SearchBase = "OU=Users,DC=YOUR,DC=DOMAIN,DC=NAME" # OU with users
$Server = "\\YOUR-SERVER\home$"

$UserList = Get-ADUser -SearchBase $SearchBase -filter {Enabled -eq $true} -Properties HomeDirectory | Where {$_.HomeDirectory -eq $null} | ForEach {$_.SamAccountName}

if ($Userlist -ne $null) {

    ForEach ($User in $UserList) {

        $HomeFolderPath = "$Server\$User"

        #Create home folder for user
        if (-Not (Test-Path $HomeFolderPath)) {

            New-Item -Path $HomeFolderPath -itemtype Directory -force | Out-Null

            Write-Host "Created: " -nonewline -foregroundcolor cyan; Write-Host "$Server\$User" -foregroundcolor magenta
        }

        $Acl = Get-Acl -Path $HomeFolderPath

        $Ace = New-Object System.Security.AccessControl.FileSystemAccessRule("$Domain\$User", "Modify, ChangePermissions", "ContainerInherit,ObjectInherit", "None", "Allow")

        $Acl.AddAccessRule($Ace)

        Set-Acl -Path $HomeFolderPath -AclObject $Acl

        #Connect home folder in AD as disk H:
        Set-ADUser -Identity $User -HomeDrive "H:" -HomeDirectory $HomeFolderPath

        Write-Host "Set home drive for user: " -nonewline -foregroundcolor cyan; Write-Host "$User" -foregroundcolor magenta
    }
}

else { Write-Host "All homedrives are present." -foregroundcolor green }
