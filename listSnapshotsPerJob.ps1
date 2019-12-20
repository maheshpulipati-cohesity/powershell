### usage: ./expireLocalSnapshots.ps1 -vip mycluster -username admin [ -domain local ] -olderThan 365 -protectionJobName Mahesh_Test [ -expire ]

### process commandline arguments
[CmdletBinding()]
param (
    [Parameter(Mandatory = $True)][string]$vip, #the cluster to connect to (DNS name or IP)
    [Parameter(Mandatory = $True)][string]$username, #username (local or AD)
    [Parameter()][string]$domain = 'local', #local or AD domain
    [Parameter(Mandatory = $True)][string]$protectionJobName #Protection Job Name corresponding to Snapshots that needs to be deleted
)

### source the cohesity-api helper code
. ./cohesity-api

### authenticate
apiauth -vip $vip -username $username -domain $domain

### cluster Id
$clusterId = (api get cluster).id


### find protectionRuns with old local snapshots that are archived and sort oldest to newest
"searching for old snapshots..."
foreach ($job in ((api get protectionJobs) | Where-Object { $_.name -eq $protectionJobName })) {
    
$runs = (api get protectionRuns?jobId=$($job.id))

write-host "Protection_Job_Name  RunDate  ExpiryDate "

foreach ($run in $runs) {

        $runDate = usecsToDate $run.copyRun[0].runStartTimeUsecs
	$expiryDate = usecsToDate $run.copyRun[0].expiryTimeUsecs
        $jobName = $run.jobName

foreach ($copyRun in $run.copyRun) {

write-host "$jobName  $runDate $expiryDate " -ForegroundColor Green
}
}

    }
