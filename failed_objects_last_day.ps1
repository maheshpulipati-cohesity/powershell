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
$startdate = Get-Date (Get-Date).ToUniversalTime().AddDays(-1) -UFormat %s 
$starttimeusecs = $startdate.PadRight(16,'0')

### Get the Failed Object Details
$failedobjects = api get /public/reports/protectionSourcesJobsSummary?allUnderHierarchy=true`&endTimeUsecs=$endtimeusecs`&reportType=kFailedObjectsReport`&startTimeUsecs=$starttimeusecs`&statuses=kError

### Capture the needed fields
$name = $clusterdetails.name
$ClusterId = $clusterdetails.id

$dateString = (get-date).ToString().Replace(' ','_').Replace('/','-').Replace(':','-')
$outfileName = "FailedObjectsLastDay-$dateString.csv" 
"Cluster Name,Cluster ID,Object Name,Environment,Job Name,JobRun Type,Error" | Out-File -FilePath $outfileName

for ($index=0; $index -lt $failedobjects.protectionSourcesJobsSummary.protectionsource.name.Length; $index++)
{
$objectname = $failedobjects.protectionSourcesJobsSummary[${index}].protectionsource.name
$environment = $failedobjects.protectionSourcesJobsSummary[${index}].protectionsource.environment
$jobname = $failedobjects.protectionSourcesJobsSummary[${index}].jobName
$jobruntype = $failedobjects.protectionSourcesJobsSummary[${index}].lastRunType
$error = $failedobjects.protectionSourcesJobsSummary[${index}].lastRunErrorMsg

"$name,$ClusterId,$objectname,$environment,$jobname,$jobruntype,$error" | Out-File -FilePath $outfileName -Append
}
