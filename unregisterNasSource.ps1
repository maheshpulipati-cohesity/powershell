### usage: ./unregisterNasSource.ps1 -vip mycluster -username admin -nasSource mynas 

### process commandline arguments
[CmdletBinding()]
param (
    [Parameter(Mandatory = $True)][string]$vip, #Cohesity cluster to connect to
    [Parameter(Mandatory = $True)][string]$username, #Cohesity username
    [Parameter()][string]$domain = 'local', #Cohesity user domain name
    [Parameter(Mandatory = $True)][string]$nasSource #Name of the NAS Source to Unregister
)


### source the cohesity-api helper code
. ./cohesity-api

### authenticate
apiauth -vip $vip -username $username -domain $domain

### get NAS Source ID
$nasSourceId = (api get /public/protectionSources/objects | Where-Object { $_.name -eq $nasSource }).id

Write-Output "Unregistering NAS Source $nasSource ...."

$result = api delete /public/protectionSources/$nasSourceId
