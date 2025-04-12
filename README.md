# BackupStation.ps1

This is a PowerShell script I wrote to automate backing up test station files — specifically config and project folders — to both a network share and a local archive. It runs quietly in the background on each test station and doesn't need any user interaction once set up.

---

## 🔧 What it Does

- Checks a shared `.ini` file for a global on/off flag (`scriptStatus`)
- Copies relevant project/config folders from the local machine to a structured backup location
- Avoids copying stuff that doesn’t matter (like logs, test images, and empty `.db` files from the test app)
- Creates backup folders using the current date so everything stays organized
- Logs all operations so I (or someone else) can check what happened if something goes wrong
- Structured with functions to make the script easier to read and update

---

## 📁 Folder Structure

```text
├── C:    
├── clips\                        # Config files live here
└── TestApp 
        ├── MyProject\            # Project folder to back up
        └── AutomationScripts\
            └── backupScriptsLog\ # Where the logs go
```

---

## ⚙️ Configuration

This script pulls a global value from a shared `.ini` file:

```ini
scriptStatus=1
```

This flag acts as a kind of global emergency stop — if I need to stop all test station backups at once, I can just flip it to `0`.

> **Why aren't paths and folder names in the `.ini` too?**  
Each test station is set up differently. They might use different names, folders, or drives. If everything came from the same `.ini`, the files wouldn't copy since every test has unique standardized file names. That’s why only the global stuff goes in the config file. The rest stays in the script — specific to each station.

---

## 🚀 How to Run It

1. Drop the script on the machine and make sure the folders match
2. Make sure `BackupStation.ini` is reachable from the network
3. Run the script manually or through Task Scheduler
4. That’s it — it handles logging and folder creation on its own

---

## 🔧 Functions in the Script

- `Load-ConfigVariables`: Gets global flags from the `.ini`
- `Copy-ConfigFiles`: Copies config folders to local and network backup
- `Copy-TestImages`: Handles test images separately
- `Copy-FilteredProjectFiles`: Copies only useful project files
- `Run-BackupStation`: Orchestrates the whole backup

---

## 🛠️ Improvements I Plan to Make

- Add `try/catch` blocks so errors don’t go silent
- Add a dry-run mode to preview actions before copying
- Improve how file exclusions work (support for wildcards)
- Move path setup into its own function to tidy things up

---

## 👋 Who Made This

**Radu Jorda**  
DevOps-Focused Automation Engineer (in progress, but getting there)


---

## ⏰ Automation via Task Scheduler

This script is scheduled to run automatically using Windows Task Scheduler.

- Registered under: `\AutomationScripts\BackupStation`
- Trigger: **Every day at 19:00**
- It launches PowerShell with:
  ```bash
  C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe
  -NoProfile -WindowStyle Hidden -file "C:\TestApp\AutomationScripts\backupStation.ps1"
  ```

This setup ensures each test station runs the backup script without any user interaction. If needed, the exported task file (`BackupStation-Task.xml`) can be re-imported to restore the schedule.



---

## 🧩 Additional Cleanup Scripts

These are two short helper scripts I wrote for keeping things clean after the backups are done.

- **BackupStationLocalManager.ps1**  
  This one runs at the end of every backup job.  
  It checks the local backup folder and deletes anything older than 31 days (if there are more than 31 folders).  
  I added it so I don’t end up keeping outdated backups that serve no purpose — but still have at least one around in case something breaks on a machine that doesn’t get updated often.

- **BackupStationServerManager.ps1**  
  This one runs separately, not from the script — it’s scheduled on a different machine, the one that holds the main network backup.  
  It deletes network backups that are older than 7–8 days. I set it up mostly for redundancy and space management.
