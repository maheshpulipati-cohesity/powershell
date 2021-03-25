### usage: ./vault_write_bandwidth_multiple_clusters.ps1
###Author: Mahesh Pulipati

### source the cohesity-api helper code
. ./cohesity-api

### Create the Output CSV file 
$dateString = (get-date -Format d).ToString().Replace(' ','_').Replace('/','-').Replace(':','-')
$outfileName = "VaultWriteBandwidth-$dateString.csv"

### Read the Input CSV file for multiple clusters
$inputcsv = Import-Csv ./vault_write_bandwidth_multiple_clusters_input.csv

### Fetch the needed fields from the Input CSV
for ($index1=0; $index1 -lt $inputcsv.vip.Length; $index1++)
{
$vip = $inputcsv[${index1}].vip
$username = $inputcsv[${index1}].username
$password = $inputcsv[${index1}].apikey

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

### Capture the needed Cluster fields
$name = $clusterdetails.name
$ClusterId = $clusterdetails.id

### Append Cluster Name and Headers to the Output CSV
"********************* $name *********************" | Out-File -FilePath $outfileName -Append
"Timestamp,Write Bandwidth (MB/s)" | Out-File -FilePath $outfileName -Append

### Get the External Target Write Bandwidth Details
$vaultstats = api get statistics/timeSeriesStats?endTimeMsecs=$endtimemsecs`&entityId=$ClusterId`&metricName=kNumBytesWritten`&metricUnitType=0`&range=date`&rollupFunction=rate`&rollupIntervalSecs=3600`&schemaName=kIceboxClusterVaultStats`&startTimeMsecs=$starttimemsecs

### Capture and print the needed Write Bandwidth detais
for ($index2=0; $index2 -lt $vaultstats.dataPointVec.timestampMsecs.Length; $index2++)
{
$timestampmsecs = $vaultstats.dataPointVec.timestampMsecs[${index2}] -replace ".{3}$"
$writebw = $vaultstats.dataPointVec.data[${index2}].int64Value

$timestamp = Get-Date -UnixTimeSeconds $timestampmsecs | Get-Date -Format G
$writebwMB = [math]::round($writebw/1048576, 2)
"$timestamp,$writebwMB" | Out-File -FilePath $outfileName -Append
}
"`n" | Out-File -FilePath $outfileName -Append
}
