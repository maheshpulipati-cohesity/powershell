### usage: ./updateJobIndexing.ps1 -vip mycluster -username admin -password password -protectionJobName mynas 

### process commandline arguments
[CmdletBinding()]
param (
    [Parameter(Mandatory = $True)][string]$vip, #Cohesity cluster to connect to
    [Parameter(Mandatory = $True)][string]$username, #Cohesity username
    [Parameter()][string]$domain = 'local', #Cohesity user domain name
    [Parameter(Mandatory = $True)][string]$password, #Cohesity password
    [Parameter(Mandatory = $True)][string]$protectionJobName #Name of the Protection Job to update Indexing
)


### authenticate
Connect-CohesityCluster -Server $vip -Credential (New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $username, (ConvertTo-SecureString -AsPlainText $password -Force))

### get protection Job details
$jobName = Get-CohesityProtectionJob -Names $protectionJobName
$jobId = $jobName.Id

Write-Output "Job ID for the Protection Job $protectionJobName is $jobId..."
$job = Get-CohesityProtectionJob -Ids $jobId

echo "`n"

### Update the Indexing for the Protection Job
$job.IndexingPolicy.AllowPrefixes = "/"
$job.IndexingPolicy.DisableIndexing = $false
$job | Set-CohesityProtectionJob

echo "`n"
