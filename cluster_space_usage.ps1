### usage: ./cluster_space_usage.ps1 -vip 10.10.10.10 -username admin -password pass

### process commandline arguments
[CmdletBinding()]
param (
    [Parameter(Mandatory = $True)][string]$vip, #the cluster to connect to (DNS name or IP)
    [Parameter(Mandatory = $True)][string]$username, #username (local or AD)
    [Parameter()][string]$domain = 'local', #local or AD domain
    [Parameter(Mandatory = $True)][string]$password #Password
)

### source the cohesity-api helper code
. ./cohesity-api

### authenticate
apiauth -vip $vip -username $username -domain $domain -password $password

### Get the Cluster Information
$clusterdetails = api get /public/cluster

### Get the Storage Stats 
$storagestats = api get /public/stats/storage

### Get the Cluster Stats
$clusterstats = api get cluster?fetchTimeSeriesSchema=true`&fetchStats=true

### Capture the needed fields
$name = $clusterdetails.name
$ClusterId = $clusterdetails.id

$RawCapacity = $storagestats.totalCapacityBytes
$UsedCapacity = $storagestats.localUsageBytes
$AvailCapacity = $storagestats.localAvailableBytes
$Utilization = [math]::round($UsedCapacity/$RawCapacity, 3)*100

$RawCapacityTB = [math]::round($RawCapacity/1099511627776, 2)
$UsedCapacityTB = [math]::round($UsedCapacity/1099511627776, 2)
$AvailCapacityTB = [math]::round($AvailCapacity/1099511627776, 2)

$DataINBeforeReduction = $clusterStats.stats.usagePerfStats.dataInBytes
$DataINAfterReduction = $clusterStats.stats.usagePerfStats.dataInBytesAfterReduction
$DedupRatio = [math]::round($DataINBeforeReduction/$DataINAfterReduction, 2)

$dateString = (get-date).ToString().Replace(' ','_').Replace('/','-').Replace(':','-')
$outfileName = "ClusterSpaceUsage-$dateString.csv" 
"Cluster Name,Cluster ID,Raw Capacity(TB),Physical Usage(TB),Available Capacity(TB),Utilization(%),Dedupe Ratio" | Out-File -FilePath $outfileName

"$name,$ClusterId,$RawCapacityTB,$UsedCapacityTB,$AvailCapacityTB,$Utilization,$DedupRatio" | Out-File -FilePath $outfileName -Append
