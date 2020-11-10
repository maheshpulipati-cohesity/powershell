### usage: ./updateViewProperties.ps1 -vip mycluster -username admin -password password -viewname myview 

### process commandline arguments
[CmdletBinding()]
param (
    [Parameter(Mandatory = $True)][string]$vip, #Cohesity cluster to connect to
    [Parameter(Mandatory = $True)][string]$username, #Cohesity username
    [Parameter()][string]$domain = 'local', #Cohesity user domain name
    [Parameter(Mandatory = $True)][string]$password, #Cohesity password
    [Parameter(Mandatory = $True)][string]$viewname #Name of the View to update SMB permissions and other properties
)

### authenticate
Connect-CohesityCluster -Server $vip -Credential (New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $username, (ConvertTo-SecureString -AsPlainText $password -Force))

### get view details
$view = Get-CohesityView -ViewNames $viewname

### set enableOfflineCaching to True
$view.EnableOfflineCaching=1

Set-CohesityView -View $view

### set Antivirus Scanning to enabled
$a = New-Object -TypeName Cohesity.Model.AntivirusScanConfig("")
$a.IsEnabled=1
$view.AntivirusScanConfig = $a

Set-CohesityView -View $view

### set permissions on the View
$smbObject = [Cohesity.Model.SmbPermissionsInfo]::new()
$smbObject.Permissions = [Cohesity.Model.SmbPermission]::new()
$smbObject.Permissions[0].Access = [Cohesity.Model.SmbPermission+AccessEnum]::KFullControl
$smbObject.Permissions[0].Mode = [Cohesity.Model.SmbPermission+ModeEnum]::KFolderSubFoldersAndFiles
$smbObject.Permissions[0].Type = [Cohesity.Model.SmbPermission+TypeEnum]::KAllow
$smbObject.Permissions[0].Sid = "S-1-1-0"

$view.SmbPermissionsInfo.OwnerSid = "S-1-1-0"

$view.SmbPermissionsInfo.Permissions = $smbObject.Permissions

$view.SharePermissions = [Cohesity.Model.SmbPermission]::new()
$view.SharePermissions[0].Access = [Cohesity.Model.SmbPermission+AccessEnum]::KFullControl
$view.SharePermissions[0].Type = [Cohesity.Model.SmbPermission+TypeEnum]::KAllow
$view.SharePermissions[0].Sid = "S-1-1-0"

Set-CohesityView -View $view

echo "`n"
