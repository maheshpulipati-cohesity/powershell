### usage: ./createSMBView.ps1 -vip mycluster -username myusername -domain mydomain.net -viewName newview1 -readWrite mydomain.net\server1 -fullControl mydomain.net\admingroup1 -qosPolicy 'TestAndDev High' -storageDomain mystoragedomain

### process commandline arguments
[CmdletBinding()]
param (
    [Parameter(Mandatory = $True)][string]$vip,       # the cluster to connect to (DNS name or IP)
    [Parameter(Mandatory = $True)][string]$username,  # username (local or AD)
    [Parameter()][string]$domain = 'local',           # local or AD domain
    [Parameter(Mandatory = $True)][string]$viewName,  # name of view to modify
    [Parameter()][array]$readWrite,                   # list of users to grant read/write
    [Parameter()][array]$readOnly,                    # list of users to grant read-only
    [Parameter()][array]$modify                      # list of users to grant modify
)
### source the cohesity-api helper code
. $(Join-Path -Path $PSScriptRoot -ChildPath cohesity-api.ps1)

### authenticate
apiauth -vip $vip -username $username -domain $domain



$viewPerms = @{
"sharePermissions" = @(
      @{
        "sid" = "S-1-1-0";
        "access" = "kFullControl";
        "mode" = "kFolderSubFoldersAndFiles";
        "type" = "kAllow"
      }
    );
    "smbPermissionsInfo" = @{
      "ownerSid" = "S-1-5-32-544";
      "permissions" = @()
    };
 };

### add permissions
function addPermission($user, $perms){
    $domain, $domainuser = $user.split('\')
    $principal = api get "activeDirectory/principals?domain=$domain&includeComputers=true&search=$domainuser" | Where-Object fullName -eq $domainuser
    if($principal){
        $permission = @{
            "sid" = $principal.sid;
            "type" = "kAllow";
            "mode" = "kFolderSubFoldersAndFiles";
            "access" = $perms
        }
        $viewPerms.smbPermissionsInfo.permissions += $permission
    }else{
        Write-Warning "User $user not found"
        exit 1
    }    
}

foreach($user in $readWrite){
    addPermission $user 'kReadWrite'
}

foreach($user in $fullControl){
    addPermission $user 'kFullControl'
}

foreach($user in $readOnly){
  addPermission $user 'kReadOnly'
}

foreach($user in $modify){
  addPermission $user 'kModify'
}

### Modify the view
"Updating Permissions view $viewName..."
$null = api put views $viewName

