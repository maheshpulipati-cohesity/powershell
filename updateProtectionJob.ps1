### usage: ./updateProtectionJob.ps1 -vip mycluster -username admin -protectionJobName Ajit_Test -policyName Mahesh_test 

### process commandline arguments
[CmdletBinding()]
param (
    [Parameter(Mandatory = $True)][string]$vip, #Cohesity cluster to connect to
    [Parameter(Mandatory = $True)][string]$username, #Cohesity username
    [Parameter()][string]$domain = 'local', #Cohesity user domain name
    [Parameter(Mandatory = $True)][string]$protectionJobName, #Name of the protection job to modify the policy for
    [Parameter(Mandatory = $True)][string]$policyName #Name of the protection policy to be assigned
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

### find the protection policy exists
$policies = api get protectionPolicies?names=$policyName

if(! $policies){
    Write-Warning "Can't find Protection Policy $policyName"
    exit
}
#echo $policies.name

if($policies){
    echo "Protection Policy $policyName exists"

#echo $policies.Id

### Get the Protection Job ID
$JobId = $protectionJob.Id


### Modify the Protection Job with the new Policy

$protectionJob.policyID = $policies.Id

$result = api put protectionJobs/$JobId $protectionJob

}else{

"Protection Job cannot be updated"
    }

}
