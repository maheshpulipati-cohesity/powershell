Get-VM |
Select Name,
@{N="Datastore";E={[string]::Join(',',(Get-Datastore -Id $_.DatastoreIdList | Select -ExpandProperty Name))}},
@{N="UsedSpaceGB";E={[math]::Round($_.UsedSpaceGB,1)}},
@{N="ProvisionedSpaceGB";E={[math]::Round($_.ProvisionedSpaceGB,1)}},
@{N="Folder";E={$_.Folder.Name}} |
Export-Csv StorageSizebyVM.csv -NoTypeInformation -UseCulture
