<#
.SYNOPSIS
    Backup users profiles remotely.
.DESCRIPTION
    A remote version of USMT-Backup.ps1 using PsExec. For a detailed description
    please refer to the original USMT-Backup.ps1
.NOTES
    Version:            1.0
    Author:             Daniel Allen
    Last Modified Date: 16.08.2016
.EXAMPLE
    ./USMT-Backup-Remote.ps1
#>

$MigStore = "\\YOUR\SERVER\UserProfile$"

$USMT = "\\PATH\TO\YOUR\USMT"

$PsExec = "\\PATH\TO\YOUR\PsExec.exe"

$Computer = Read-Host "Enter hostname"

Write-Host "Checking connectivity..." -foregroundcolor yellow

if (-Not (Test-Path $USMT)) {

    Write-Host "Couldn't reach USMT. Check your network connection" -foregroundcolor red

    Read-Host "Press Enter to exit" | Out-Null
}

elseif (-Not (Test-Path $MigStore)) {

    Write-Host "Couldn't reach Migration Store. Check your network connection" -foregroundcolor red

    Read-Host "Press Enter to exit" | Out-Null
}

elseif (-Not (Test-Connection $Computer -Count 2 -quiet)) {

    Write-Host "Couldn't reach specified hostname. Check your network connection" -foregroundcolor red

    Read-Host "Press Enter to exit" | Out-Null
}

else {

    Write-Host "Copying USMT to target machine..." -foregroundcolor yellow

    ### Determine target machine architecture
    $Arch = Get-WmiObject win32_operatingsystem -Computer $Computer | ForEach { $_.OSArchitecture }

    if ($Arch -eq "32-bit") {

        Copy-Item -Path "$USMT\x86" -Destination "\\$Computer\c$\Temp\USMT" -Recurse -Container -Force | Out-Null
    }

    else {

        Copy-Item -Path "$USMT\amd64" -Destination "\\$Computer\c$\Temp\USMT" -Recurse -Container -Force | Out-Null
    }

    Copy-Item -Path $PsExec -Destination $env:TEMP -Force | Out-Null

    Set-Location -Path $env:TEMP

	Write-Host "Checking for existing migration..." -foregroundcolor yellow

	if (Test-Path $MigStore\$Computer\USMT\USMT.MIG) {

		Write-Host "Found existing migration. Do you want to delete it and start over? Y/N" -foregroundcolor yellow
		$Response = Read-Host

		if ($Response -eq "N") {
			Exit
		}
	}

    Write-Host "Starting migration..." -foregroundcolor yellow

    & .\PsExec.exe \\$Computer -s -w C:\Temp\USMT -accepteula C:\Temp\USMT\scanstate.exe $MigStore\$Computer /v:13 /c /o /i:MigUser.xml /i:MigApp.xml /targetWindows7 /localonly /uel:30 /l:$MigStore\$Computer\scanstate.log

    Write-Host "Done! Migration file is saved in " -foregroundcolor green -nonewline; Write-Host "$MigStore\$Computer\USMT\USMT.MIG" -foregroundcolor cyan
}
