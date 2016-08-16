<#
.SYNOPSIS
    Disable inactive users in AD.
.DESCRIPTION
    This script will look for AD users that haven't logged in the last $Date days
    and disable their accounts. It sends the list of disabled accounts to specified
    email address afterwards.
.NOTES
    Version:            1.0
    Author:             Daniel Allen
    Last Modified Date: 16.08.2016
.EXAMPLE
    ./AD-Disable-Inactive-Users.ps1
#>

Import-Module ActiveDirectory

# Adjust this according to your inactivity policy
$Date = (Get-Date).AddDays(-44)

$Descr = "Disabled automatically due to inactivity."

$SearchBase = "OU=Users,DC=YOUR,DC=DOMAIN,DC=NAME" # OU with users

# Set your server and recipients
$SMTPServer = "10.10.10.10"
$SMTPPort = "25"
$Recipients= "john.doe@domain.com", "jane.doe@domain.com"

$Userlist = Get-ADUser -SearchBase $SearchBase -Filter {Enabled -eq $true -and PasswordNeverExpires -eq $False} -Properties LastLogonTimeStamp | Select-Object SamAccountName,@{n='LastLogonTimeStamp';e={[DateTime]::FromFileTime($_.LastLogonTimeStamp)}} | Where {$_.LastLogonTimeStamp -lt $Date -and $_.LastLogonTimeStamp -gt (Get-Date).AddDays(-9000)}

ForEach ($User in $Userlist) {

    Set-ADUser -Identity $User.SamAccountName -Description $Descr

    Disable-ADAccount -Identity $User.SamAccountName

    Write-Host "$($User.SamAccountName) has been disabled due to inactivity" -foregroundcolor yellow
}

$nl = [Environment]::NewLine

$UsersSAM = $Userlist.SamAccountName | Sort | ForEach {"$_$nl"}

$Body = "<font face='Arial' size=3><p>The following accounts have been disabled due to inactivity:</p><br>$UsersSAM</font>"

Send-MailMessage -To $Recipients -Subject "Inactive accounts since $($Date.ToString("dd.MM.yyyy"))" -From "AD-Disable-Inactive-Users" -BodyAsHtml $Body -SmtpServer $SMTPServer -Port $SMTPPort -Encoding ([System.Text.Encoding]::UTF8)
