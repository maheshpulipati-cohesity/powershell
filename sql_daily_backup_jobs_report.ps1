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

### Get the Object Details
$objectruns = api get /public/reports/protectionSourcesJobsSummary?allUnderHierarchy=true`&endTimeUsecs=$endtimeusecs`&reportType=kProtectionSummaryByObjectTypeReport`&startTimeUsecs=$starttimeusecs`&environments=kSQL

### Capture the needed fields
$name = $clusterdetails.name
$ClusterId = $clusterdetails.id

$dateString = (get-date).ToString().Replace(' ','_').Replace('/','-').Replace(':','-')
$outfileName = "SQLDailyBackupObjectsReport-$dateString.csv" 
"Cluster Name,Cluster ID,Object Name,Job Name,Environment,JobRun Type,JobRun Status,Start Time,End Time,Data Read(MB),Logical Data(GB)" | Out-File -FilePath $outfileName

for ($index=0; $index -lt $objectruns.protectionSourcesJobsSummary.protectionsource.name.Length; $index++)
{
$objectname = $objectruns.protectionSourcesJobsSummary[${index}].protectionSource.name
$jobname = $objectruns.protectionSourcesJobsSummary[${index}].jobName
$environment = $objectruns.protectionSourcesJobsSummary[${index}].protectionSource.environment
$jobruntype = $objectruns.protectionSourcesJobsSummary[${index}].lastRunType
$jobrunstatus = $objectruns.protectionSourcesJobsSummary[${index}].lastRunStatus
$runstarttimeepoch = $objectruns.protectionSourcesJobsSummary[${index}].lastRunStartTimeUsecs -replace ".{6}$"
$runendtimeepoch = $objectruns.protectionSourcesJobsSummary[${index}].lastRunEndTimeUsecs -replace ".{6}$"
$dataread = $objectruns.protectionSourcesJobsSummary[${index}].numDataReadBytes
$logicaldata = $objectruns.protectionSourcesJobsSummary[${index}].numLogicalBytesProtected


$runstarttime = Get-Date -UnixTimeSeconds $runstarttimeepoch | Get-Date -Format G
$runendtime = Get-Date -UnixTimeSeconds $runendtimeepoch | Get-Date -Format G

$datareadMB = [math]::round($dataread/1048576, 2)
$logicaldataGB = [math]::round($logicaldata/1073741824, 2)
"$name,$ClusterId,$objectname,$jobname,$environment,$jobruntype,$jobrunstatus,$runstarttime,$runendtime,$datareadMB,$logicaldataGB" | Out-File -FilePath $outfileName -Append
}
