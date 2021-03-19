Connect-CohesityCluster -Server 10.16.16.171

$runs = Get-CohesityProtectionJobRun -JobId (Get-CohesityProtectionJob -Names 'kb1').id

"startDate,status,durationSecs,bytesRead,bytesWritten" | Out-File -FilePath ./myjobruns.csv

foreach ($run in $runs){
    $startUsecs = $run.BackupRun.Stats.StartTimeUsecs
    $endUsecs = $run.BackupRun.Stats.EndTimeUsecs
    $durationSecs = ($endUsecs - $startUsecs)/1000000
    $bytesRead = $run.BackupRun.Stats.TotalBytesReadFromSource
    $bytesWritten = $run.BackupRun.Stats.TotalPhysicalBackupSizeBytes
    $startDate = Convert-CohesityUsecsToDateTime -Usecs $startUsecs
    $status = $run.BackupRun.Status
    "$startDate, $status, $durationSecs, $bytesRead, $bytesWritten"
    "$startDate,$status,$durationSecs,$bytesRead,$bytesWritten" | Out-File -FilePath ./myjobruns.csv -Append
}
