### usage: ./unregisterPhysicalSource.ps1 -vip mycluster -username admin -source mynas 

### process commandline arguments
[CmdletBinding()]
param (
    [Parameter(Mandatory = $True)][string]$vip, #Cohesity cluster to connect to
    [Parameter(Mandatory = $True)][string]$username, #Cohesity username
    [Parameter()][string]$domain = 'local', #Cohesity user domain name
    [Parameter(Mandatory = $True)][string]$source #Name of the Source to Unregister
)


### source the cohesity-api helper code
. ./cohesity-api

### authenticate
apiauth -vip $vip -username $username -domain $domain

### get NAS Source ID
$SourceId = (api get /public/protectionSources/objects | Where-Object { $_.name -eq $source -and ($_.environment -eq 'kPhysical') }).id

Write-Output "Unregistering Physical Source $source ...."

$result = api delete /public/protectionSources/$SourceId
