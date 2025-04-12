# BackupStation.ps1
# Version: 1.6
# Author: Radu Jorda
# Purpose: Backup local config and project directories to a network location and local archive
# Usage: Runs automatically based on config values. Designed for station automation environments.

# TODOs for Future Enhancements:
# - Add try/catch around file operations for better error handling
# - Replace string-based exclusions with wildcard-friendly matching
# - Add dry-run mode for testing backups without writing files

function Load-ConfigVariables {
    param ([string]$ConfigPath)
    $config = Get-Content -Path $ConfigPath
    foreach ($line in $config) {
        if ($line -match "=") {
            $kv = $line -split "="
            if ((Get-Variable $kv[0] -ErrorAction SilentlyContinue) -eq $null) {
                New-Variable $kv[0] -Value $kv[1]
            } else {
                Set-Variable $kv[0] -Value $kv[1]
            }
        }
    }
}

function Copy-ConfigFiles {
    Copy-Item $sourceConfigPath -Destination $localConfigBackupPath -Recurse -Force
    Copy-Item $sourceConfigPath -Destination $destinationConfigPath -Recurse -Force
}

function Copy-TestImages {
    Copy-Item $testImagesSourcePath -Destination $testImagesBackupPath -Recurse -Force
}

function Copy-FilteredProjectFiles {
    param (
        [string[]]$ExcludeList,
        [string]$SourcePath,
        [string]$DestNetworkPath,
        [string]$DestLocalPath
    )
    foreach ($file in Get-ChildItem $SourcePath -Name) {
        if ($ExcludeList -notcontains $file) {
            $itemPath = Join-Path $SourcePath $file
            Write-Host "Copying: $itemPath"

            if (!(Test-Path $DestNetworkPath) -and (Test-Path $itemPath -PathType Container)) {
                New-Item -Path $DestNetworkPath -ItemType Directory | Out-Null
            }
            Copy-Item $itemPath -Destination $DestNetworkPath -Recurse -Force

            if (!(Test-Path $DestLocalPath) -and (Test-Path $itemPath -PathType Container)) {
                New-Item -Path $DestLocalPath -ItemType Directory | Out-Null
            }
            Copy-Item $itemPath -Destination $DestLocalPath -Recurse -Force
        }
    }
}

function Run-BackupStation {
    # --- Configuration and Paths ---
    $stationName                = "TestStation"
    $localScriptDir            = "C:\TestApp\AutomationScripts\\backupScriptsLog"
    $standardConfigDir         = "C:\\"
    $standardProjectDir        = "C:\TestApp"
    $customConfigDir           = "Configurator"
    $customProjectDir          = "MyProject"
    $networkBackupRoot         = "\fileserver\client\project\TestBackup"
    $configBackupFolderName    = "Configurator"
    $projectBackupFolderName   = "MyProject"
    $clientFolder              = "Client"
    $currentDate               = Get-Date -Format "dd-MM-yyyy"
    $testImagesDir             = "Test_Images"
    $localBackupDir            = "Backup"
    $logFileName               = "backupScriptLogfile.txt"

    # --- Build Paths ---
    $sourceConfigPath          = Join-Path $standardConfigDir $customConfigDir
    $destinationConfigPath     = Join-Path $networkBackupRoot -ChildPath ("$currentDate\$clientFolder\$stationName\$configBackupFolderName")
    $sourceProjectPath         = Join-Path $standardProjectDir $customProjectDir
    $destinationProjectPath    = Join-Path $networkBackupRoot -ChildPath ("$currentDate\$clientFolder\$stationName\$projectBackupFolderName")
    $localProjectBackupPath    = Join-Path $standardConfigDir ("$localBackupDir\$currentDate\$projectBackupFolderName")
    $logFilePath               = Join-Path $localScriptDir ("$currentDate\$logFileName")
    $localConfigBackupPath     = Join-Path $standardConfigDir ("$localBackupDir\$currentDate\$configBackupFolderName")
    $testImagesSourcePath      = Join-Path $standardProjectDir ("$customProjectDir\$testImagesDir")
    $testImagesBackupPath      = Join-Path $standardConfigDir ("$localBackupDir\$testImagesDir")

    # --- Start Logging ---
    Start-Transcript -Path $logFilePath -Append -NoClobber

    # --- Run Copy Tasks ---
    Copy-ConfigFiles
    Copy-TestImages

    $exclude = @("logs_old_trasability", "logs_old_trasability", "logs", "Test_Images", "test_images", "backup", "Backup", "Process", "Sample working folder", "*.db")
    Copy-FilteredProjectFiles -ExcludeList $exclude -SourcePath $sourceProjectPath -DestNetworkPath $destinationProjectPath -DestLocalPath $localProjectBackupPath

    # --- Call Local Manager Script ---
    $currentDir = $PSScriptRoot
    & (Join-Path $currentDir "BackupStationLocalManager.ps1")

    Stop-Transcript
}

# --- ENTRY POINT/MAIN Load Config and Execute ---
$configIniPath = "\\fileserver\department\\AutomationScriptsConfigs\BackupStation\BackupStation.ini"
Load-ConfigVariables -ConfigPath $configIniPath

if ($scriptStatus -eq 1) {
    Run-BackupStation
}
