### usage: ./deleteFolderVMware.ps1 -datastore <datastore> -folder <folder>

### process commandline arguments
[CmdletBinding()]
param (
    [Parameter(Mandatory = $True)][string]$datastore, #Datastore from which the folder needs to be deleted
    [Parameter(Mandatory = $True)][string]$folder #Folder which needs to be deleted
)

echo $datastore
echo $folder

$servInst = Get-View -Id ServiceInstance

$fileMgr = Get-View -Id $servInst.Content.FileManager

$dc = Get-View -VIObject (Get-Datacenter)

# start the task

$taskMoRef = $fileMgr.DeleteDatastoreFile_Task("[$datastore] $folder", $dc.MoRef)


# wait until the task is done

$task = Get-View -Id $taskMoRef

while (@("running", "queued") -contains $task.Info.State) {

     start-sleep 1

     $task = Get-View -Id $taskMoRef
}
