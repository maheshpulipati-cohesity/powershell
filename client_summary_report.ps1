### usage: ./failed_objects_last_day.ps1 -vip 10.10.10.10 -username admin -password pass

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

### Get the End Date
$enddate = Get-Date (Get-Date).ToUniversalTime() -UFormat %s
$endtimeusecs = $enddate.PadRight(16,'0')

### Get the Start Date
$startdate = Get-Date (Get-Date).ToUniversalTime().AddDays(-30) -UFormat %s 
$starttimeusecs = $startdate.PadRight(16,'0')

### Get the Object Details
$objectruns = api get /public/reports/protectionSourcesJobsSummary?allUnderHierarchy=true`&endTimeUsecs=$endtimeusecs`&reportType=kProtectionSummaryByObjectTypeReport`&startTimeUsecs=$starttimeusecs

### Capture the needed fields
$name = $clusterdetails.name
$ClusterId = $clusterdetails.id

$dateString = (get-date).ToString().Replace(' ','_').Replace('/','-').Replace(':','-')
$outfileName = "ClientSummaryReport-$dateString.csv" 
"Cluster Name,Cluster ID,Object Name,Job Name,Total Runs,Successful Runs,Failed Runs,Success(%)" | Out-File -FilePath $outfileName

for ($index=0; $index -lt $objectruns.protectionSourcesJobsSummary.protectionsource.name.Length; $index++)
{
$objectname = $objectruns.protectionSourcesJobsSummary[${index}].protectionSource.name
$jobname = $objectruns.protectionSourcesJobsSummary[${index}].jobName
$totalsnapshots = $objectruns.protectionSourcesJobsSummary[${index}].numSnapshots
$errorsnapshots = $objectruns.protectionSourcesJobsSummary[${index}].numErrors
$warningsnapshots = $objectruns.protectionSourcesJobsSummary[${index}].numWarnings

$successfulruns = $totalsnapshots - $errorsnapshots
$successpercent = [math]::round($successfulruns/$totalsnapshots, 3)*100

"$name,$ClusterId,$objectname,$jobname,$totalsnapshots,$successfulruns,$errorsnapshots,$successpercent" | Out-File -FilePath $outfileName -Append
}
