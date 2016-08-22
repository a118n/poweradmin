<#
.SYNOPSIS
    Change users's signature in Outlook.
.DESCRIPTION
    This is a modified version of Daniel Classon's script to set user's signature in Outlook:
    http://www.danielclasson.com/powershell-script-to-set-outlook-signature-in-office-2010-and-office-2013-using-information-populated-from-active-directory/

    This script is intended to be deployed through GPO as login script.
    It doesn't touch existing signatures, but creates new one and sets it as default for new, as well as reply/forwarded messages.
    It will use prepared template as a base and Active Directory's user properties to fill in dynamic data.

    The full list of properties used:

    [Placeholder in Template - AD Property]

    AD_DisplayName - DisplayName
    AD_Title - title
    AD_Department - department
    AD_Company - company
    AD_Telephone - telephoneNumber
    AD_MobilePhone - mobile
    AD_Email - mail

    Therefore, it is requied for user to have these properties, otherwise there will be blanks in his signature.


.NOTES
    Version:            1.4
    Author:             Danil Allen
    Original Author:    Daniel Classon
    Last Modified Date: 22.08.2016
.EXAMPLE
    ./Set-Outlook-Signature.ps1
#>

# Signature variables
$SignatureName = "Signature" # Change this to whatever your file name is
$LocalSignaturePath = (Get-Item env:appdata).Value + "\Microsoft\Signatures"
$RemoteSignature = "\\PATH\TO\YOUR\SIGNATURE\$SignatureName.docx" # Point this to where your signature is located on a network share


# Get Active Directory information for current user
$Searcher = New-Object System.DirectoryServices.DirectorySearcher
$Searcher.Filter = "(&(objectCategory=User)(samAccountName=$env:username))"
$ADUserPath = $Searcher.FindOne()
$ADUser = $ADUserPath.GetDirectoryEntry()

# Get user properties for signature
$ADDisplayName = $ADUser.DisplayName
$ADLocalizedName = $ADUser.extensionAttribute10
$ADEmailAddress = $ADUser.mail
$ADTitle = $ADUser.title
$ADLocalizedTitle = $ADUser.extensionAttribute13
$ADTelephoneNumber = $ADUser.telephoneNumber
$ADMobilePhone = $ADUser.mobile
$ADDepartment = $ADUser.department
$ADCompany = $ADUser.company
$ADLocalizedCompany = $ADUser.extensionAttribute1


### Copy signature templates to local Signature folder

# If there's no folder, create it
if (-Not (Test-Path $LocalSignaturePath)) { New-Item -Path $LocalSignaturePath -Itemtype Directory -Force | Out-Null }

# If there's a file with the same name, delete it and create a folder
if (-Not (Test-Path $LocalSignaturePath -pathType container)) {

    Remove-Item -Path $LocalSignaturePath -Force
    New-Item -Path $LocalSignaturePath -Itemtype Directory -Force | Out-Null
}

# Copy template file to user's appdata
Copy-Item -Path $RemoteSignature -Destination $LocalSignaturePath -Force


### Insert variables from Active Directory to Signature File

# Parameters for changing strings in Word file
$ReplaceAll = 2
$FindContinue = 1
$MatchCase = $False
$MatchWholeWord = $True
$MatchWildcards = $False
$MatchSoundsLike = $False
$MatchAllWordForms = $False
$Forward = $True
$Wrap = 1
$Format = $False

$MSWord = New-Object -com word.application

$MSWord.Documents.Open("$LocalSignaturePath\$SignatureName.docx")

$FindText = "AD_DisplayName"
$ReplaceText = $ADDisplayName.ToString()
$MSWord.Selection.Find.Execute($FindText, $MatchCase, $MatchWholeWord,	$MatchWildcards, $MatchSoundsLike, $MatchAllWordForms, $Forward, $Wrap,	$Format, $ReplaceText, $ReplaceAll)

$FindText = "AD_Title"
$ReplaceText = $ADTitle.ToString()
$MSWord.Selection.Find.Execute($FindText, $MatchCase, $MatchWholeWord,	$MatchWildcards, $MatchSoundsLike, $MatchAllWordForms, $Forward, $Wrap,	$Format, $ReplaceText, $ReplaceAll)

$FindText = "AD_Department"
$ReplaceText = $ADDepartment.ToString()
$MSWord.Selection.Find.Execute($FindText, $MatchCase, $MatchWholeWord,	$MatchWildcards, $MatchSoundsLike, $MatchAllWordForms, $Forward, $Wrap,	$Format, $ReplaceText, $ReplaceAll)

$FindText = "AD_Telephone"
$ReplaceText = $ADTelephoneNumber.ToString()
$MSWord.Selection.Find.Execute($FindText, $MatchCase, $MatchWholeWord,	$MatchWildcards, $MatchSoundsLike, $MatchAllWordForms, $Forward, $Wrap,	$Format, $ReplaceText, $ReplaceAll)

$FindText = "AD_MobilePhone"
$ReplaceText = $ADMobilePhone.ToString()
$MSWord.Selection.Find.Execute($FindText, $MatchCase, $MatchWholeWord,	$MatchWildcards, $MatchSoundsLike, $MatchAllWordForms, $Forward, $Wrap,	$Format, $ReplaceText, $ReplaceAll)

$FindText = "AD_Company"
$ReplaceText = $ADCompany.ToString()
$MSWord.Selection.Find.Execute($FindText, $MatchCase, $MatchWholeWord,  $MatchWildcards, $MatchSoundsLike, $MatchAllWordForms, $Forward, $Wrap, $Format, $ReplaceText, $ReplaceAll)

$MSWord.Selection.Find.Execute("AD_Email")
$MSWord.ActiveDocument.Hyperlinks.Add($MSWord.Selection.Range, "mailto:"+$ADEmailAddress.ToString(), $missing, $missing, $ADEmailAddress.ToString())


# Save Signature files in multiple extensions (needed for Outlook)
$saveFormat = [Enum]::Parse([Microsoft.Office.Interop.Word.WdSaveFormat], "wdFormatHTML");
$path = "$LocalSignaturePath\$SignatureName.htm"
$MSWord.ActiveDocument.SaveAs([ref]$path, [ref]$saveFormat)

$saveFormat = [Enum]::Parse([Microsoft.Office.Interop.Word.WdSaveFormat], "wdFormatRTF");
$path = "$LocalSignaturePath\$SignatureName.rtf"
$MSWord.ActiveDocument.SaveAs([ref] $path, [ref]$saveFormat)

$saveFormat = [Enum]::Parse([Microsoft.Office.Interop.Word.WdSaveFormat], "wdFormatText");
$path = "$LocalSignaturePath\$SignatureName.txt"
$MSWord.ActiveDocument.SaveAs([ref] $path, [ref]$SaveFormat)

$MSWord.ActiveDocument.Close()
$MSWord.Quit()


# Set signature as default
$MSWord = New-Object -com word.application
$EmailOptions = $MSWord.EmailOptions
$EmailSignature = $EmailOptions.EmailSignature
$EmailSignatureEntries = $EmailSignature.EmailSignatureEntries
$EmailSignature.NewMessageSignature = $SignatureName
$EmailSignature.ReplyMessageSignature = $SignatureName
$MSWord.Quit()
