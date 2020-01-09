### usage: ./updatePassword.ps1 -vip mycluster -username admin -domain local -targetUsername rotate -newPassword <Password>

### process commandline arguments
[CmdletBinding()]
param (
    [Parameter(Mandatory = $True)][string]$vip, #Cohesity cluster to connect to
    [Parameter(Mandatory = $True)][string]$username, #Cohesity username
    [Parameter()][string]$domain = 'local', #Cohesity user domain name
    [Parameter(Mandatory = $True)][string]$viewName, #Name of the policy to manage
    [Parameter(Mandatory = $True)][int64]$newExpiryDate
)

### source the cohesity-api helper code
. ./cohesity-api

### authenticate
apiauth -vip $vip -username $username -domain $domain

### get the user properties for the defined Target User
$views = api get views
$view = $views | Where-Object { $_.name -eq $viewName }

    $newUpdatedExpiry = @{
		'name' = $viewName;
		'viewId' = $view.viewId;
		'viewBoxId' = $view.viewBoxId;
		'basicMountPath' = $view.basicMountPath;
		'dataLockExpiryUsecs' = $newExpiryDate;
		'qos' = $view.qos;
	}

"updating expiry date for view $viewName..."
$result = api put views $newUpdatedExpiry
