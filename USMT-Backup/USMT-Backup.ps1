<#
.SYNOPSIS
    Backup users profiles.
.DESCRIPTION
    This script will backup all active user profiles as well as their AppData.
    By default it migrates only users who logged in in the last 30 days (/uel:30).
    You could exclude specific accounts by passing /ue switch, for example: /ue:DOMAIN\JDoe
    Backup is done via Microsoft's USMT tool, so you have to download and extract it from Windows ADK.
    Create USMT folder on a network share (don't forget to specify it in $USMT variable)
    and put x86 and x64 versions of USMT inside x86 and amd64 folders, respectively.
    Or change the paths manually in the script (lines 48 & 50).

    More about USMT: https://technet.microsoft.com/en-us/library/hh825256.aspx
    Download Windows ADK here: https://www.microsoft.com/en-us/download/details.aspx?id=30652
.NOTES
    Version:            1.2
    Author:             Daniel Allen
    Last Modified Date: 16.08.2016
.EXAMPLE
    ./USMT-Backup.ps1
#>

$MigStore = "\\YOUR\SERVER\UserProfile$"

$USMT = "\\PATH\TO\YOUR\USMT"

Write-Host "Checking connectivity..." -foregroundcolor yellow

if (-Not (Test-Path $USMT)) {

    Write-Host "Couldn't reach USMT. Check your network connection" -foregroundcolor red

    Read-Host "Press Enter to exit" | Out-Null
}

elseif (-Not (Test-Path $MigStore)) {

    Write-Host "Couldn't reach Migration Store. Check your network connection" -foregroundcolor red

    Read-Host "Press Enter to exit" | Out-Null
}

else {

    Write-Host "Mapping USMT drive..." -foregroundcolor yellow

    if ($env:PROCESSOR_ARCHITECTURE -eq "x86") { NET USE M: $USMT\x86 }

    else { NET USE M: $USMT\amd64 }

    cd M:\

	Write-Host "Checking for existing migration..." -foregroundcolor yellow

	if (Test-Path $MigStore\$env:COMPUTERNAME\USMT\USMT.MIG) {

		Write-Host "Found existing migration. Do you want to delete it and start over? Y/N" -foregroundcolor yellow
		$Response = Read-Host

		if ($Response -eq "N") {
			Exit
		}
	}

    Write-Host "Starting migration..." -foregroundcolor yellow

    & .\scanstate.exe $MigStore\$env:COMPUTERNAME /v:13 /c /o /i:MigUser.xml /i:MigApp.xml /targetWindows7 /localonly /uel:30 /l:$MigStore\$env:COMPUTERNAME\scanstate.log

    NET USE M: /delete /Y

    Write-Host "Done! Migration file is saved in " -foregroundcolor green -nonewline; Write-Host "$MigStore\$env:COMPUTERNAME\USMT\USMT.MIG" -foregroundcolor cyan
}
