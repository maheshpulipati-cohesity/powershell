### usage: ./resumeProtectionJob.ps1 -vip mycluster -username admin -protectionJobName Ajit_Test 

### process commandline arguments
[CmdletBinding()]
param (
    [Parameter(Mandatory = $True)][string]$vip, #Cohesity cluster to connect to
    [Parameter(Mandatory = $True)][string]$username, #Cohesity username
    [Parameter()][string]$domain = 'local', #Cohesity user domain name
    [Parameter(Mandatory = $True)][string]$protectionJobName #Name of the protection job to resume
)


### source the cohesity-api helper code
. ./cohesity-api

### authenticate
apiauth -vip $vip -username $username -domain $domain

### get existing protection jobs
$protectionJobs = api get protectionJobs?names=$protectionJobName

### find the protection job exists
$protectionJob = $protectionJobs | Where-Object { $_.name -eq $protectionJobName }
if(! $protectionJob){
    Write-Warning "Can't find Protection Job  $protectionJobName"
    exit
}
# echo $protectionJob

if($protectionJob){
    echo "Protection Job $protectionJobName exists"

}

### Get the Protection Job ID
$JobId = $protectionJob.Id


### Resume the Protection Job

echo "Resuming $protectionJobName Protection Job...."

api post protectionJobState/$JobId @{ 'pause'= $false}

