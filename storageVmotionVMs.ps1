$VMsToRelocate = Import-Csv "ListOfVMsToRelocate.csv"
$Datastore = Get-Datastore -Name "blr-sre-clu1_Datastore01"
foreach ($VM in $VMsToRelocate)
{
Write-Host "Relocating VM:" $VM.Name "to" $Datastore
Get-VM -Name $VM.Name | Move-VM -datastore $Datastore > $null
}
Write-Host "Completed!"
