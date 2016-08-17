<#
.SYNOPSIS
    Rename user's AD account and send him new credentials by email.
.DESCRIPTION
    This script will rename user's AD account, including the following attributes:

    DisplayName
    DistinguishedName
    GivenName
    Surname
    UserPrincipalName

    It will send email with updated credentials to user's email address.
.NOTES
    Version:            1.0
    Author:             Daniel Allen
    Last Modified Date: 16.08.2016
.EXAMPLE
    ./AD-Rename-User.ps1
#>

Import-Module ActiveDirectory

$SearchBase = "OU=Users,DC=YOUR,DC=DOMAIN,DC=NAME" # OU with users

$PrincipalTail = "@your.domain.net"

# Change this to your SMTP server & port
$SMTPServer = "10.10.10.10"
$SMTPPort = "25"

$User = Read-host "Enter user's new name ( First Last )"

$Error.Clear()

$FirstName = $User.Split( )[0]

$LastName = $User.Split( )[1]

# Make new SamAccountName from First and Last names.
# Default format is: first letter of first name + 7 letters of last name
# You can change it to whatever your company's policy is.
if ($LastName.Length -le "7") { $NewSAM = $FirstName.Substring(0,1) + $LastName }
else { $NewSAM = $FirstName.Substring(0,1) + $LastName.Substring(0,7) }

$CurrentSAM = Read-Host "Enter user's current SamAccountName"

$CurrentDN = Get-ADUser -SearchBase $SearchBase -filter {SamAccountName -eq $CurrentSAM} | foreach {$_.DistinguishedName}

$Principal = $FirstName + "." + $LastName + $PrincipalTail

$Recipient = Get-ADUser -SearchBase $SearchBase -filter {SamAccountName -eq $CurrentSAM} -Properties Mail | Select-Object -ExpandProperty Mail

$Body="<font face='Calibri' size=4><p>Hello, $User</p>Your account has been renamed.<br><p>Your new account name: <b><font color=red>$NewSAM</b></font><br><b><font color=red>Your password stays the same.</font></b></p><b><font color=red>On your next login please use the new account name.</b></font></font>"

try {

	#Check if SamAccountName is already in use
	$ExistingSAM = Get-ADUser -SearchBase $SearchBase -filter {SamAccountName -eq $NewSAM} | foreach {$_.SamAccountName}

	if ($ExistingSAM -eq $NewSAM) {

		#Check if it's the same user by comparing GUIDs
		$CurrentGUID = Get-ADUser -SearchBase $SearchBase -filter {SamAccountName -eq $CurrentSAM} | foreach {$_.objectGUID}

		$ExistingGUID = Get-ADUser -SearchBase $SearchBase -filter {SamAccountName -eq $NewSAM} | foreach {$_.objectGUID}

		#If GUIDs are different, ask for a new SamAccountName
		if ($CurrentGUID -ne $ExistingGUID) {

			$ExistingUser = Get-ADUser -SearchBase $SearchBase -filter {SamAccountName -eq $NewSAM} | foreach {$_.Name}

			do {

				Write-Host "`nSeems like " -foregroundcolor yellow -nonewline; Write-Host "$NewSAM" -foregroundcolor magenta -nonewline; Write-Host " SamAccountName is already in use by " -foregroundcolor yellow -nonewline; Write-Host "$ExistingUser`n" -foregroundcolor magenta

				$NewSAM = Read-Host "Please enter new SamAccountName for $User"
			}

			while ($NewSAM -eq $ExistingSAM)
		}
	}

    Rename-ADObject -Identity $CurrentDN -NewName $User

    Set-ADUser $CurrentSAM -DisplayName $User -GivenName $FirstName -Surname $LastName -SamAccountName $NewSAM -UserPrincipalName $Principal

    Write-Host "`nSuccessfully renamed $User`n" -foregroundcolor green
	Write-Host "Old name: $CurrentSAM => New name: $NewSAM" -foregroundcolor green

    Send-MailMessage -To $Recipient -from "AD-Rename-User" -Subject "Account renamed" -BodyAsHtml $Body -SmtpServer $SMTPServer -Port $SMTPPort -Encoding ([System.Text.Encoding]::UTF8)
}

catch {

    Write-Host "`nThere was an error(s) renaming $User :`n" -foregroundcolor magenta

    ForEach ($Err in $Error) { Write-Host "$Err `n" -foregroundcolor red }
}
