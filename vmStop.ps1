$vmlist = Get-VM | Format-Table -AutoSize | grep -i poweredon | awk '{print $1}'
foreach($vm in $vmlist){
Stop-VM -VM $vm -Confirm:$false
}
