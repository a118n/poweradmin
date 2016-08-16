<#
.SYNOPSIS
    Install new HP Printer on a Print Server
.DESCRIPTION
    This script will add DHCP reservation with specified ip address and hostname and then create the printer on a print server.
    By default it uses HP Universal Driver. After executing this script, reboot the device and verify that everything was set up correctly.
    Also, it requires custom module Microsoft.DHCP.PowerShell.Admin:
    https://gallery.technet.microsoft.com/scriptcenter/05b1d766-25a6-45cd-a0f1-8741ff6c04ec

.NOTES
    Version:            1.0
    Author:             Daniel Allen
    Last Modified Date: 16.08.2016
.EXAMPLE
    ./New-HP-Printer-Setup.ps1
#>

#Requires -Version 4.0

### Modules and Variables
Import-Module Microsoft.DHCP.PowerShell.Admin
$DHCPServer = "YOUR.DHCP.SERVER"
$Scope = "10.10.10.0" # Printers scope on a DHCP Server
$PrintServer = "YOUR.PRINT.SERVER"
$PrintDriver = "HP Universal Printing PCL 6"
$Hostname = Read-Host "Enter desired printer hostname"
$IP = Read-Host "Enter desired printer ip address for DHCP reservation"
$MAC = Read-Host "Enter printer's MAC address"
########################


### Add DHCP Reservation for printer
New-DHCPReservation -Server $DHCPServer -Scope $Scope -IPAddress $IP -MACAddress $MAC -Name $Hostname | Out-Null

Write-Host "Added DHCP Reservation: " -foregroundcolor cyan -nonewline; Write-Host $Hostname -foregroundcolor magenta -nonewline; Write-Host " on " -foregroundcolor cyan -nonewline; Write-Host "$DHCPServer" -foregroundcolor magenta
####################################


Write-Host "Restart the printer and make sure the correct IP address was obtained." -backgroundcolor black -foregroundcolor yellow

Read-Host "After checking, press Enter to continue" | Out-Null


### Create Port on a Print Server
function CreatePrinterPort {

    $port = ([WMICLASS]"\\$PrintServer\ROOT\cimv2:Win32_TCPIPPrinterPort").createInstance()
    $port.Name = $Hostname
    $port.SNMPEnabled = $true
    $port.SNMPCommunity = "public"
    $port.Protocol = 1
    $port.Portnumber = "9100"
    $port.HostAddress = $IP
    $port.Put()
}

CreatePrinterPort | Out-Null
################################


### Install Printer on a Print Server
function CreatePrinter {

    $print = ([WMICLASS]"\\$PrintServer\ROOT\cimv2:Win32_Printer").createInstance()
    $print.Drivername = $PrintDriver
    $print.PortName = $Hostname
    $print.Shared = $true
    $print.Published = $false
    $print.Sharename = $Hostname
    $print.DeviceID = $Hostname
    $print.Caption = $Hostname
    $print.EnableBIDI = $true
    $print.Put()
}

CreatePrinter | Out-Null

Write-Host "Created printer: " -foregroundcolor cyan -nonewline; Write-Host "$Hostname" -foregroundcolor magenta -nonewline; Write-Host " on " -foregroundcolor cyan -nonewline; Write-Host "$PrintServer" -foregroundcolor magenta
###################################
