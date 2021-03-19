### usage: ./fileSQLView.ps1 -vip mycluster -username admin [ -domain local ] -protectionJob fileSQLJobName -runId 123456 -sourceSQL sql001 -targetSQL sql002 -snapshotDate '2020-05-05 13:00:00' -windowsUser "corp.com\johndoe"

### process commandline arguments
[CmdletBinding()]
param (
    [Parameter(Mandatory = $True)][string]$vip, #the cluster to connect to (DNS name or IP)
    [Parameter(Mandatory = $True)][string]$username, #username (local or AD)
    [Parameter()][string]$domain = 'local', #local or AD domain
    [Parameter(Mandatory = $True)][string]$protectionJob, #Protection Job Name Source SQL server is part of
    [Parameter(Mandatory = $True)][string]$runId,
    [Parameter(Mandatory = $True)][string]$sourceSQL, #SQL ServerName that corresponds to DB's that need to be Restored
    [Parameter(Mandatory = $True)][string]$targetSQL, #SQL ServerName to which we need to present the Restore View
    [Parameter(Mandatory = $True)][string]$snapshotDate, #Restore Time that corresponds to the Snapshot for which we need to get the Restore View in format MM/DD/YYYY
    [Parameter(Mandatory = $True)][string]$windowsUser #Windows Domain user that should have access to this View
)

### source the cohesity-api helper code
. ./cohesity-api

### authenticate
apiauth -vip $vip -username $username -domain $domain

### cluster Id
$clusterId = (api get cluster).id

### cluster Incarnation Id
$clusterIncId = (api get cluster).incarnationId

### get Source SQL Entity ID
$sources = api get protectionSources?environments=kSQL
$serverSource = $sources[0].nodes | Where-Object {$_.protectionSource.name -eq $sourceSQL}
$sourceSQLEntityId = $serverSource.protectionSource.id
$sourceSQLTempId = $sourceSQLEntityId - 1


### get Target SQL IP
$targetSQLIp = ([System.Net.Dns]::GetHostAddresses("$targetSQL")).IPAddressToString
$subnetMask = "/24"
$cidr = "$targetSQLIp+$subnetMask"

### get Job ID
$jobId = (api get protectionJobs?names=$protectionJob).id

### get Run ID

### workflow to create Temporary Clone View

### Get Storage Domain ID from Protection Job
$sdId = (api get protectionJobs?names=$protectionJob).viewBoxId 

$curTime = Get-Date -format "yyyy-MM-dd_HH-mm"

$viewName = $sourceSQL+"_"+"$curTime"

function netbitsToDDN($netBits){
    $maskBits = '1' * $netBits + '0' * (32 - $netBits)
    $octet1 = [convert]::ToInt32($maskBits.Substring(0,8),2)
    $octet2 = [convert]::ToInt32($maskBits.Substring(8,8),2)
    $octet3 = [convert]::ToInt32($maskBits.Substring(16,8),2)
    $octet4 = [convert]::ToInt32($maskBits.Substring(24,8),2)
    return "$octet1.$octet2.$octet3.$octet4"
}

function newWhiteListEntry($cidr, $smbAccess){
    $ip, $netbits = $cidr -split '/'
    $maskDDN = netbitsToDDN $netbits
    $whitelistEntry = @{
        "smbAccess" = $smbAccess;
        "ip"            = $ip;
        "netmaskIp4"    = $maskDDN
    }
    return $whitelistEntry
}

### build subnetWhiteList
$subnetWhitelist = @()
foreach($cidr in $targetSQLIp){
    $subnetWhitelist += newWhiteListEntry $cidr 'kReadWrite'
}


$newView = @{
    "enableSmbAccessBasedEnumeration" = $true;
    "enableSmbViewDiscovery" = $true;
    "fileDataLock" = @{
      "lockingProtocol" = "kSetReadOnly"
    };
    "fileExtensionFilter" = @{
      "isEnabled" = $false;
      "mode" = "kBlacklist";
      "fileExtensionsList" = @()
    };
    "securityMode" = "kNativeMode";
    "smbPermissionsInfo" = @{
      "ownerSid" = "S-1-5-32-544";
      "permissions" = @()
    };
    "overrideGlobalWhitelist" = $true;
	"protocolAccess" = "kSMBOnly";
    "subnetWhitelist" = $subnetWhitelist;
    "qos" = @{
      "principalName" = "Backup Target High"
    };
    "viewBoxId" = $sdId;
    "caseInsensitiveNamesEnabled" = $true;
    "storagePolicyOverride" = @{
      "disableInlineDedupAndCompression" = $false
    };
    "name" = $viewName
}

function addPermission($user, $perms){
    $domain, $domainuser = $user.split('\')
    $principal = api get "activeDirectory/principals?domain=$domain&includeComputers=true&search=$domainuser" | Where-Object fullName -eq $domainuser
    if($principal){
        $sid = $principal.sid
        $permission = @{
            "sid" = $principal.sid;
            "type" = "kAllow";
            "mode" = "kFolderSubFoldersAndFiles";
            "access" = $perms
        }
        $newView.smbPermissionsInfo.permissions += $permission
    }else{
        Write-Warning "User $user not found"
        exit 1
    }    
}

foreach($user in $windowsUser){
    addPermission $user 'kFullControl'
}

### create the view
"Creating view $viewName..."
$null = api post views $newView

### constructing the Magneto Internal View Path

$magneto_view = "/magneto_"+$clusterId+"_"+$clusterIncId+"_"+$jobId

$Folder_1 = "/"+$clusterId+":"+$clusterIncId+":"+"9007199254739991"

$Folder_2 = "/host-"+$clusterId+":"+$clusterIncId+":"+$sourceSQLTempId

$Folder_3 = "/"+"$jobId"+"-"+"$runId"+"-"+"1"

$sourceDir = $magneto_view+$Folder_1+$Folder_2+$Folder_3

echo $sourceDir

#### constructing the Clone View Path
$targetView = "/"+$viewName
$targetDir = "restore"

echo $targetView

### clone Source Directory to Target Directory
$cloneDir = @{
  "destinationDirectoryName" = "$targetDir";
  "destinationParentDirectoryPath" = "$targetView";
  "sourceDirectoryPath" = "$sourceDir"
}

api post /public/views/cloneDirectory $cloneDir

