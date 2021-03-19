$csv = import-csv file.csv 
$csv | foreach-object {
  $Path = $_.path
  $owner =$_.owner
  "The username is $Path and the owner is $owner"
}
