# BackupStationServerManager.ps1
# Cleans up server backup folders older than 8 days (if more than 7 exist)
function Clean-ServerBackups {
    param (
        [string]$BackupPath = "\\fileserver\client\project",
        [int]$MaxDays = 8,
        [int]$MinCount = 7
    )

    $backupDirs = Get-ChildItem -Path $BackupPath | Where-Object { $_.PSIsContainer }
    $sortedBackups = $backupDirs | Sort-Object { [datetime]::ParseExact($_.Name, "dd-MM-yyyy", $null) }
    $today = Get-Date

    foreach ($folder in $sortedBackups) {
        $folderDate = [datetime]::ParseExact($folder.Name, "dd-MM-yyyy", $null)
        $age = ($today - $folderDate).Days

        if ($age -gt $MaxDays -and $sortedBackups.Count -gt $MinCount) {
            Remove-Item $folder.FullName -Recurse -Force
            Write-Output "Deleted server backup: $($folder.FullName) (Age: $age days)"
        } else {
            Write-Output "Server backups are within retention range. Nothing deleted."
        }
    }
    exit 0
}
# --- ENTRY POINT/MAIN Clean-ServerBackups ---
Clean-ServerBackups