<#
.SYNOPSIS
    Restore users profiles.
.DESCRIPTION
    This script will restore user profiles from USMT-Backup (if any).
.NOTES
    Version:            1.0
    Author:             Daniel Allen
    Last Modified Date: 16.08.2016
.EXAMPLE
    ./USMT-Restore.ps1
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

elseif (-Not (Test-Path $MigStore\$env:COMPUTERNAME\USMT\USMT.MIG)) {

    Write-Host "Couldn't find migration file for $env:COMPUTERNAME" -foregroundcolor red

    Read-Host "Press Enter to exit" | Out-Null
}

else {

    Write-Host "Mapping USMT drive..." -foregroundcolor yellow

    if ($env:PROCESSOR_ARCHITECTURE -eq "x86") { NET USE M: $USMT\x86 }

    else { NET USE M: $USMT\amd64 }

    cd M:\

    Write-Host "Starting deployment..." -foregroundcolor yellow

    & .\loadstate.exe $MigStore\$env:COMPUTERNAME /v:13 /i:MigUser.xml /i:MigApp.xml /l:$MigStore\$env:COMPUTERNAME\loadstate.log

    NET USE M: /delete /Y

    Write-Host "Done! Migration file has been restored" -foregroundcolor green

    Read-Host "Press Enter to exit" | Out-Null
}
