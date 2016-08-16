<#
.SYNOPSIS
    Get new accounts
.DESCRIPTION
    This script will retrieve all newly created accounts and send email with attached csv.
    By default, time span is a week from today, but this can be controlled with the $Date variable.
.NOTES
    Version:            1.0
    Author:             Daniel Allen
    Last Modified Date: 16.08.2016
.EXAMPLE
    ./AD-Get-New-Accounts.ps1
#>

Import-Module ActiveDirectory

$Date = (Get-Date).AddDays(-7)

$SearchBase = "OU=Users,DC=YOUR,DC=DOMAIN,DC=NAME" # OU with users

# Set your server and recipients
$SMTPServer = "10.10.10.10"
$SMTPPort = "25"
$Recipients= "john.doe@domain.com", "jane.doe@domain.com"

$Userlist = Get-ADUser -SearchBase $SearchBase -Filter * -Properties DisplayName,Description,Office,Mail,WhenCreated,WhenChanged,PwdLastSet,LastLogonTimeStamp | Where {$_.WhenCreated -ge $Date} | Select-Object DisplayName,Description,Office,Mail,WhenCreated,WhenChanged,PwdLastSet,@{n='LastLogonTimeStamp';e={[DateTime]::FromFileTime($_.LastLogonTimeStamp)}} | Export-CSV -Path "NewAccounts-$(Get-Date -f dd.MM.yyyy).csv" -NoTypeInformation

$Attachment = "NewAccounts-$(Get-Date -f dd.MM.yyyy).csv"
$Body = "<font face='Arial' size=3><p>Accounts created in the last week, starting from $($Date.ToString("dd.MM.yyyy HH:mm"))</p></font>"
Send-MailMessage -To $Recipients -Subject "New Accounts Since $($Date.ToString("dd.MM.yyyy"))" -From "AD-Get-New-Accounts" -BodyAsHtml $Body -Attachments $Attachment -SmtpServer $SMTPServer -Port $SMTPPort -Encoding ([System.Text.Encoding]::UTF8)

Remove-Item -Path $Attachment -Force
