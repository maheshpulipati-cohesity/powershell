### usage: ./getVMProtectionJob.ps1 -vip mycluster -username admin

### process commandline arguments
[CmdletBinding()]
param (
    [Parameter(Mandatory = $True)][string]$vip, #Cohesity cluster to connect to
    [Parameter(Mandatory = $True)][string]$username, #Cohesity username
    [Parameter()][string]$domain = 'local' #Cohesity user domain name
)


### source the cohesity-api helper code
. ./cohesity-api

### authenticate
apiauth -vip $vip -username $username -domain $domain

### get existing protection jobs

api get protectionJobs?names | grep kVMware -B 1 | grep name | cut -d ":" -f 2 | sed -e 's/^[ \t]*//'

