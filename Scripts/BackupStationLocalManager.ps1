# BackupStationLocalManager.ps1
# Cleans up local backup folders older than 31 days (if more than 31 exist)
function Clean-LocalBackups {
    param (
        [string]$BackupPath = "C:\backup",
        [int]$MaxDays = 31,
        [int]$MinCount = 31
    )

    $backupDirs = Get-ChildItem -Path $BackupPath | Where-Object { $_.PSIsContainer }
    $sortedBackups = $backupDirs | Sort-Object { [datetime]::ParseExact($_.Name, "dd-MM-yyyy", $null) }
    $today = Get-Date

    foreach ($folder in $sortedBackups) {
        $folderDate = [datetime]::ParseExact($folder.Name, "dd-MM-yyyy", $null)
        $age = ($today - $folderDate).Days

        if ($age -gt $MaxDays -and $sortedBackups.Count -gt $MinCount) {
            Remove-Item $folder.FullName -Recurse -Force
            Write-Output "Deleted local backup: $($folder.FullName) (Age: $age days)"
        } else {
            Write-Output "Local backups are within retention range. Nothing deleted."
        }
    }
    exit 0
}
# --- ENTRY POINT/MAIN Clean-LocalBackups ---
Clean-LocalBackups

