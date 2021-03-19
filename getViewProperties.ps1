### usage: ./getViewProperties.ps1 -vip 10.16.16.161 -username admin -password admin -viewName helloworld

### process commandline arguments
[CmdletBinding()]
param (
    [Parameter(Mandatory = $True)][string]$vip, #the cluster to connect to (DNS name or IP)
    [Parameter(Mandatory = $True)][string]$username, #username (local or AD)
    [Parameter(Mandatory = $True)][string]$password, #password
    [Parameter(Mandatory = $True)][string]$viewName #Name of the View
)

### Connect to Cohesity Cluster
Connect-CohesityCluster -Server $vip -Credential (New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $username, (ConvertTo-SecureString -AsPlainText $password -Force))

### Get View Properties
$view = Get-CohesityView -ViewNames $viewName

### Print the Specific View Properties
$viewname = $view.Name
$viewid = $view.ViewId
$QOS = $view.Qos.PrincipalName

Write-Host "$viewname,$viewid,$QOS"
