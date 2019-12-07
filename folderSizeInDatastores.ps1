$datastores = Get-Datastore

foreach($ds in $datastores){

    New-PSDrive -Location $ds -Name DS -PSProvider VimDatastore -Root "\" > $null

    Get-ChildItem -Path DS: | where{$_.ItemType -eq 'Folder' -and $_.Name -notmatch '^\.|^vmk|^esxconsole|tmp'} | %{

        New-Object PSObject -Property @{

            Datastore = $ds.Name

            Folder = $_.Name

            SizeGB = [math]::Round((Get-ChildItem -Path "DS:\$($_.Name)" | Measure-Object -Property Length -Sum | select -ExpandProperty Sum)/1GB,1)

        }

    }

    Remove-PSDrive -Name DS -Confirm:$false
}
