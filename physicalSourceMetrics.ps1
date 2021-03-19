### usage: ./physicalSourceMetrics.ps1 -vip mycluster -username admin [ -domain local ]

### process commandline arguments
[CmdletBinding()]
param (
    [Parameter(Mandatory = $True)][string]$vip, #the cluster to connect to (DNS name or IP)
    [Parameter(Mandatory = $True)][string]$username, #username (local or AD)
    [Parameter()][string]$domain = 'local' #local or AD domain
)

### source the cohesity-api helper code
. ./cohesity-api

### authenticate
apiauth -vip $vip -username $username -domain $domain

### cluster Id
$clusterId = (api get cluster).id


write-host "Name,JobName,Logical,UniqueOnPrimary"

### find protectionRuns with old local snapshots with archive tasks and sort oldest to newest
foreach ($storage in (api get /reports/objects/storage?msecsBeforeEndTime=172800000)) {
    
    foreach ($storagesource in $storage) {

        $name = $storagesource.name
        $jobName = $storagesource.jobName
	$logical = $storage.dataPoints[0].logicalSizeBytes
	$uniqueprimary = $storage.physicalSizeBytesOnPrimary	

        ### Display Metrics
                    Write-Host "$name,$jobName,$logical,$uniqueprimary" -ForegroundColor Yellow
                }
            }
