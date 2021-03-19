foreach($vmlist in (Get-Content -Path vmListPoweredOn.csv)){
$vm = Get-VM -Name $vmlist
Start-VM -VM $vm -Confirm:$false
}
