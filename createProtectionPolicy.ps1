### usage: ./createProtectionPolicy.ps1 -vip mycluster -username admin -policyName mypolicy -daysToKeepLocal 30 -daysToKeepArchive 30 -archiveTo s3_bucket

### process commandline arguments
[CmdletBinding()]
param (
    [Parameter(Mandatory = $True)][string]$vip, #Cohesity cluster to connect to
    [Parameter(Mandatory = $True)][string]$username, #Cohesity username
    [Parameter()][string]$domain = 'local', #Cohesity user domain name
    [Parameter(Mandatory = $True)][string]$policyName, #Name of the policy to manage
    [Parameter(Mandatory = $True)][int]$daysToKeepLocal,
    [Parameter(Mandatory = $True)][int]$daysToKeepArchive,
    [Parameter(Mandatory = $True)][string]$archiveTo
)


### source the cohesity-api helper code
. ./cohesity-api

### authenticate
apiauth -vip $vip -username $username -domain $domain

### get existing policies
$policies = api get protectionPolicies?names=$policyName

### get external targets
$archives = api get vaults

### confirm external target exists
$archive = $archives | Where-Object { $_.name -eq $archiveTo }
if(! $archive){
    Write-Warning "Can't find External Target  $archiveTo"
    exit
}
echo $archive

if($policies){
    echo "policy $policyName already exists"
    exit
}else{
    $newPolicy = @{
        'name' = $policyName;
        'incrementalSchedulingPolicy' = @{
            'periodicity' = 'kDaily';
            'dailySchedule' = @{
                'days' = @()
            }
        };
        'daysToKeep' = $daysToKeepLocal;
        'retries' = 3;
        'retryIntervalMins' = 30;
        'blackoutPeriods' = @();
        'snapshotArchivalCopyPolicies' = @(
            @{
                'copyPartial' = $true;
                'daysToKeep' = $daysToKeepArchive;
                'multiplier' = 1;
                'periodicity' = 'kEvery';
                'target' = @{
                    'vaultId' = $archive.Id;
                    'vaultName' = $archive.name;
   		    'vaultType' = 'kCloud'
                 }
            }
        );
        'cloudDeployPolicies' = @()
    }
    "creating policy $policyName..."
    $result = api post protectionPolicies $newPolicy
}


