### usage: ./listSnapshotStatus.ps1 -vip 10.16.16.171 -username admin -protectionJobName blrcohoshare_backup

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


### show protectionRuns for each protectionJob along with Local Snapshot and Remote Snapshot Backup status 
"searching for all snapshots..."
foreach ($job in ((api get protectionJobs) | Where-Object { $_.name -eq $protectionJobName })) {
    
###$runs = (api get protectionRuns?jobId=$($job.id))

$runs = (api get protectionRuns?jobId=$($job.id)`&numRuns=999999`&runTypes=kRegular`&excludeTasks=true`&excludeNonRestoreableRuns=true) | `
    Where-Object { $_.backupRun.snapshotsDeleted -eq $false } | `
    Where-Object { $_.backupRun.runType -ne 'kLog' } | `
    Sort-Object -Property @{Expression={ $_.copyRun[0].runStartTimeUsecs }; Ascending = $True }

###$runs = api get "protectionRuns?endTimeUsecs=1577125799999000&excludeTasks=true&jobId=$($job.id)&numRuns=9999&startTimeUsecs=1554057000000000"

write-host "Protection_Job_Name		RunDate		ExpiryDate	LocalSnapshotStatus	LocalsnapshotsDeleted"

foreach ($run in $runs) {
$snapshotDeleteStatus = $run.backupRun[0].snapshotsDeleted
	if ($snapshotDeleteStatus -ne 'True') {

        $runDate = usecsToDate $run.copyRun[0].runStartTimeUsecs
	$expiryDate = usecsToDate $run.copyRun[0].expiryTimeUsecs
        $jobName = $run.jobName
	$localSnapshotStatus = $run.backupRun[0].status
	$localSnapshotDeleted = $run.backupRun[0].snapshotsDeleted
	$ArchivedSnapshotStatus = $run.copyRun[0].status

foreach ($copyRun in $run.copyRun) {

write-host "$jobName	$runDate	$expiryDate	$localSnapshotStatus	$localSnapshotDeleted" -ForegroundColor Green
}
}
#else {
#write-host ("This Protection Job does not have any Active Snapshots") 
#}
}
    }
