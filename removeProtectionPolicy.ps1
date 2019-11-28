### usage: ./removeProtectionPolicy.ps1 -vip mycluster -username admin -policyName mypolicy 

### process commandline arguments
[CmdletBinding()]
param (
    [Parameter(Mandatory = $True)][string]$vip, #Cohesity cluster to connect to
    [Parameter(Mandatory = $True)][string]$username, #Cohesity username
    [Parameter()][string]$domain = 'local', #Cohesity user domain name
    [Parameter(Mandatory = $True)][string]$policyName #Name of the policy to manage
)


### source the cohesity-api helper code
. ./cohesity-api

### authenticate
apiauth -vip $vip -username $username -domain $domain

### get existing policies
$policies = api get protectionPolicies?names=$policyName

echo $policies.Id
### check protection policy exists
if($policies){
    echo "policy $policyName does exist"
    $existingPolicy = @{
        'Id' = $policies.Id
    }
### "deleting policy $policies.name ...."

$result = Remove-CohesityProtectionPolicy -Id $policies.Id -Confirm:$false
}else{
      "policy name does not exist $policyName"
            }
