### usage: ./viewStats.ps1 -vip 10.10.10.10 -username admin -password pass

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

### Get all the View Details against the Storage Domain 

$view = api get 'views?_includeTenantInfo=true&allUnderHierarchy=true&includeInactive=true&includeStats=true&maxCount=1000'

### Get the corresponding Properties 
$dateString = (get-date).ToString().Replace(' ','_').Replace('/','-').Replace(':','-')

$outfileName = "ViewStats-$dateString.csv" 
"View Name,Logical(GB),Storage Consumed(GB),Data Written (GB),Resiliency (GB),QOS Type,Protocol Supported,View ID" | Out-File -FilePath $outfileName

for ($index=0; $index -lt $view.Views.name.Length; $index++)
{
$name = $view.Views[${index}].name
$Logical = $view.views[${index}].logicalUsageBytes
$StorageConsumed = $view.views[${index}].stats.dataUsageStats.storageConsumedBytes
$DataWritten = $view.views[${index}].stats.dataUsageStats.dataWrittenBytes
$Qos = $view.views[${index}].qos.principalName
$Protocol = $view.views[${index}].protocolAccess
$ViewId = $view.views[${index}].viewId

$LogicalGB = [math]::round($Logical/1073741824, 2)
$StorageConsumedGB = [math]::round($StorageConsumed/1073741824, 2)
$DataWrittenGB = [math]::round($DataWritten/1073741824, 2)
$ResiliencyGB = $StorageConsumedGB - $DataWrittenGB


"$name,$LogicalGB,$StorageConsumedGB,$DataWrittenGB,$ResiliencyGB,$Qos,$Protocol,$ViewId" | Out-File -FilePath $outfileName -Append
}
