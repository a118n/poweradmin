# poweradmin
Powershell scripts useful for Windows enterprise administration.

All scripts are written by me, if not stated otherwise.

For a detailed description refer to the header's `.DESCRIPTION` field, here's just a quick summary:

### Active Directory
* **AD-Add-Users-To-Group.ps1**

  Add multiple users from CSV file to a particular group.

* **AD-Connect-HomeDrives.ps1**

  Create home folders and connect them as home drive to AD users.

* **AD-Disable-Inactive-Users.ps1**

  Disable users that haven't logged in for a while.

* **AD-Get-New-Accounts.ps1**

  Get all accounts that have been created recently.

* **AD-Rename-User.ps1**

  Rename user's AD account and notify him by email.

* **AD-Switch-Group.ps1**

  Remove users from one group and add to another.

* **Get-Inactive-Computers.ps1**

  Get a list of computers where nobody logged in for a while.

* **Get-LockedOutLocation.ps1**

  An exellent function by [Jason Walker](https://blogs.technet.microsoft.com/heyscriptingguy/2012/12/27/use-powershell-to-find-the-location-of-a-locked-out-user/) to query PDC for a computer that processed a failed user logon attempt which caused the user account to become locked out.

### Backup
* **USMT-Backup**

  Powershell wrappers for Microsoft's [User State Migration Tool](https://technet.microsoft.com/en-us/library/hh825256.aspx). Basically, a one-click backup & restore solution.

* **Backup-UserProfile-USB.ps1**

  Powershell wrapper for robocopy to backup user's profile folder & other non-system folders to USB disk.

### Software
* **Install-Java.ps1**

  A one-click installer and updater. Checks for the latest JRE online prior to installing. Removes unnecessary old versions. Deploys with predefined global configuration settings & exception list, so no additional configuration is required.

* **Uninstall-Remote.ps1**

  Uninstall MSI-based software from remote PC.

### Hardware
* **New-HP-Printer-Setup.ps1**

  Create DHCP reservation & add a new HP printer on a print server.

### Misc
* **Clean-Spooler.ps1**

  Clean old spooled documents.

* **Find-Username.ps1**

  Find computers where specified user is currently logged in.

* **Fix-Acl.ps1**

  Scan all nested objects inside a folder and apply folder's ACL to them (if there's a difference).

* **Get-All-Computers-With-Users.ps1**

  Pull all computers from DC and see who is currently logged in.


* **Get-LogOn-LogOff.ps1**

  Pull Logon and Logoff events from a specified computer to see who logged in / logged out and when.
