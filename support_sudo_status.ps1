### usage: ./support_sudo_status.ps1
### Author: Mahesh Pulipati

### source the cohesity-api helper code
. ./cohesity-api

### Create the CSV file with date timestamp
$dateString = (get-date -Format d).ToString().Replace(' ','_').Replace('/','-').Replace(':','-')
$outfileName = "SupportSudoStatus-$dateString.csv"
"Cluster Name,Cluster ID,Sudo Enabled" | Out-File -FilePath $outfileName

### Read the Input CSV file for multiple clusters
$inputcsv = Import-Csv ./support_sudo_status_input.csv

### Get the needed fields from the Input CSV file
for ($index=0; $index -lt $inputcsv.vip.Length; $index++)
{
$vip = $inputcsv[${index}].vip
$username = $inputcsv[${index}].username
$password = $inputcsv[${index}].apikey

### authenticate
apiauth -vip $vip -username $username -domain local -password $password -useApiKey

### Get the Cluster Information
$clusterdetails = api get /public/cluster

### Get the Sudo status for the support user
$status = api get /nexus/security/support_user_access_info
$sudostatus = $status.isSudoAccessEnabled

### Capture the needed fields
$name = $clusterdetails.name
$ClusterId = $clusterdetails.id

"$name,$ClusterId,$sudostatus" | Out-File -FilePath $outfileName -Append
}
