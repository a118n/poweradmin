<#
.SYNOPSIS
    Fix Access Control Lists of nested objects.
.DESCRIPTION
    This script will compare ACLs of all objects in the source folder.
    Whenever there's a difference, it will replace ACL of object with source folder's ACL.
    User has a choice whether to get only files, only folders, files and folders or files and folders with recursion.
    Script will generate a log file placed in the same directory with the name "FixACL + TimeStamp" in <dd-MM-yyyy-HH-mm> format.
    It's recommended to run Powershell as Administrator, otherwise you might get "Permission Denied" errors.
.NOTES
    Version:            1.1
    Author:             Daniel Allen
    Last Modified Date: 16.08.2016
.EXAMPLE
    ./Fix-Acl.ps1
#>

do {

    Start-Transcript -Path "FixACL-$(Get-Date -f dd.MM.yyyy-HH.mm).txt"

    $SourceFolder = Read-Host "Enter source folder path"

    [int]$Choice = Read-Host "`nEnter number to choose behavior:`n
    [1] Get only files, without recursion

    [2] Get only folders, without recursion

    [3] Get files and folders, without recursion

    [4] Get files and folders, WITH recursion (Careful! Might be dangerous!)"


    $RefACL = Get-Acl -LiteralPath $SourceFolder

    function FixACL ($Target) {

        Write-Host "Getting ACLs of files in " -foregroundcolor cyan -nonewline; Write-Host "$SourceFolder" -foregroundcolor magenta

        ForEach ($Object in $Target) {

            $Comparison = Compare-Object $RefACL $Object -Property Access

            if ($Comparison -ne $null) {

                Write-Host "Changing ACL of " -foregroundcolor yellow -nonewline; Write-Host (Convert-Path -LiteralPath $Object.Path) -foregroundcolor magenta

                Set-Acl -Path $Object.Path -AclObject $RefACL
            }

            else {

                Write-Host "ACL of " -foregroundcolor cyan -nonewline; Write-Host (Convert-Path -LiteralPath $Object.Path) -foregroundcolor magenta -nonewline; Write-Host " is OK" -foregroundcolor cyan
            }
        }
    }


    if ($Choice -eq "1") {

        $Target = Get-ChildItem -Path $SourceFolder | Where {! $_.PSIsContainer} | Get-Acl

        FixACL ($Target)
    }

    elseif ($Choice -eq "2") {

        $Target = Get-ChildItem -Path $SourceFolder | Where {$_.PSIsContainer} | Get-Acl

        FixACL ($Target)
    }

    elseif ($Choice -eq "3") {

        $Target = Get-ChildItem -Path $SourceFolder | Get-Acl

        FixACL ($Target)
    }

    elseif ($Choice -eq "4") {

        $Target = Get-ChildItem -Path $SourceFolder -Recurse | Get-Acl

        FixACL ($Target)
    }

    else {

        Write-Host "Oops! Wrong number" -foregroundcolor yellow

        Stop-Transcript

        Return
    }

    Stop-Transcript

    $Response = Read-Host "`nStart Over? y/n"
}

while ($Response -eq "y")
