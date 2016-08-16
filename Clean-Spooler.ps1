<#
.SYNOPSIS
    Clean old spooled documents.
.DESCRIPTION
    This script will delete old spooled documents that are stuck in queue.
    By default time is 2 hours old, but you could adjust it via $Date variable.

.NOTES
    Version:            1.0
    Author:             Daniel Allen
    Last Modified Date: 16.08.2016
.EXAMPLE
    ./Clean-Spooler.ps1
#>

$Date = (Get-Date).AddHours(-2)

Stop-Service spooler
Sleep 5
Get-ChildItem -Path "C:\Windows\System32\spool\PRINTERS" | Where-Object { $_.LastWriteTime -lt $Date } | Remove-Item -Verbose
Start-Service spooler
