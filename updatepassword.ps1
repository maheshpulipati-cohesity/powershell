### usage: ./updatePassword.ps1 -vip mycluster -username admin -domain local -targetUsername rotate -newPassword <Password>

### process commandline arguments
[CmdletBinding()]
param (
    [Parameter(Mandatory = $True)][string]$vip, #Cohesity cluster to connect to
    [Parameter(Mandatory = $True)][string]$username, #Cohesity username
    [Parameter()][string]$domain = 'local', #Cohesity user domain name
    [Parameter(Mandatory = $True)][string]$targetUsername, #Name of the policy to manage
    [Parameter(Mandatory = $True)][string]$newPassword
)

### source the cohesity-api helper code
. ./cohesity-api

### authenticate
apiauth -vip $vip -username $username -domain $domain

### get the user properties for the defined Target User
$users = api get users
$user = $users | Where-Object { $_.username -eq $targetUsername }

    $newUpdatedPassword = @{
		'username' = $targetUsername;
		'domain' = $user.domain;
		'emailAddress' = $user.emailAddress;
		'roles' = $user.roles;
		'privilegeIds' = $user.privilegeIds;
		'clusterIdentifiers' = $user.clusterIdentifiers;
		'effectiveTimeMsecs' = $user.effectiveTimeMsecs;
		'restricted' = $user.restricted;
		'primaryGroupName' = $user.primaryGroupName;
		'createdTimeMsecs' = $user.createdTimeMsecs;
		'lastUpdatedTimeMsecs' = $user.lastUpdatedTimeMsecs
		'sid' = $user.sid
		'password' = $newPassword
	}

"updating password for user $targetUsername..."
$result = api put users $newUpdatedPassword
