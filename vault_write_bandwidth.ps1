### usage: ./vault_write_bandwidth.ps1 -vip 10.10.10.10 -username admin -password apitoken -useApiKey
###Author: Mahesh Pulipati

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
apiauth -vip $vip -username $username -domain $domain -password $password -useApiKey

### Get the Cluster Information
$clusterdetails = api get /public/cluster

### Get the End Date
$enddate = Get-Date (Get-Date).ToUniversalTime() -UFormat %s
$prevenddate = $enddate - ($enddate % 1800)
$roundenddate = ($prevenddate - 1800).ToString()
$endtimemsecs = $roundenddate.PadRight(13,'0')

### Get the Start Date
$startdate = Get-Date (Get-Date).ToUniversalTime().AddDays(-1) -UFormat %s
$prevstartdate = $startdate - ($startdate % 1800)
$roundstartdate = ($prevstartdate - 1800).ToString() 
$starttimemsecs = $roundstartdate.PadRight(13,'0')

### Capture the needed cluster fields
$name = $clusterdetails.name
$ClusterId = $clusterdetails.id

### Get the External Target Write Bandwidth details
$vaultstats = api get statistics/timeSeriesStats?endTimeMsecs=$endtimemsecs`&entityId=$ClusterId`&metricName=kNumBytesWritten`&metricUnitType=0`&range=date`&rollupFunction=rate`&rollupIntervalSecs=3600`&schemaName=kIceboxClusterVaultStats`&startTimeMsecs=$starttimemsecs

### Create the Output CSV
$dateString = (get-date -Format d).ToString().Replace(' ','_').Replace('/','-').Replace(':','-')
$outfileName = "VaultWriteBandwidth-$dateString.csv" 
"Cluster Name,Cluster ID,Timestamp,Write Bandwidth (MB/s)" | Out-File -FilePath $outfileName

###Capture the needed fields and print them to output CSV
for ($index=0; $index -lt $vaultstats.dataPointVec.timestampMsecs.Length; $index++)
{
$timestampmsecs = $vaultstats.dataPointVec.timestampMsecs[${index}] -replace ".{3}$"
$writebw = $vaultstats.dataPointVec.data[${index}].int64Value

$timestamp = Get-Date -UnixTimeSeconds $timestampmsecs | Get-Date -Format G

$writebwMB = [math]::round($writebw/1048576, 2)
"$name,$ClusterId,$timestamp,$writebwMB" | Out-File -FilePath $outfileName -Append
}
