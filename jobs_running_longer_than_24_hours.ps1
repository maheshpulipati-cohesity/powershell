### process commandline arguments
[CmdletBinding()]
param (
   [Parameter(Mandatory = $True)][string]$vip, #the cluster to connect to (DNS name or IP)
   [Parameter(Mandatory = $True)][string]$username, #username (local or AD)
   [Parameter()][string]$domain = 'local' #local or AD domain
)

### source the cohesity-api helper code
. ./cohesity-api.ps1

### authenticate
apiauth -vip $vip -username $username -domain $domain

### Get the Cluster Information
$clusterdetails = api get /public/cluster

### Capture the needed fields
$name = $clusterdetails.name
$ClusterId = $clusterdetails.id

$dateString = (get-date).ToString().Replace(' ','_').Replace('/','-').Replace(':','-')
$outfileName = "JobsRunningLongerThan24Hours-$dateString.csv" 
"Cluster Name,Cluster ID,Job Name,Start Time,Running Since,JobRun Type,Environment" | Out-File -FilePath $outfileName

$jobs = api get protectionJobs | Where-Object {$_.isActive -ne $false -and $_.isDeleted -ne $True}

foreach ($job in $jobs) {
$run = api get "protectionRuns?numRuns=1&excludeTasks=true&jobId=$($job.id)"
if ($run.backupRun.status -eq "kRunning"){
$jobname = $run.jobName
$startimesecs = $run.backupRun.stats.startTimeUsecs -replace ".{6}$"
$jobruntype = $run.backupRun.runType
$environment = $run.backupRun.environment
$startdate = Get-Date -UnixTimeSeconds $startimesecs | Get-Date -Format G 

$enddate = Get-Date -Format G
$difftime = New-TimeSpan -Start $startdate -End $enddate
$days = $difftime.Days
$hours = $difftime.Hours
$minutes = $difftime.Minutes
$runsince = "$days days $hours hours $minutes minutes"

if ($minutes -ge 1) {
"$name,$ClusterId,$jobname,$startdate,$runsince,$jobruntype,$environment" | Out-File -FilePath $outfileName -Append
}
}
}
