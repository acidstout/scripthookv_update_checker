# Grand Theft Auto V ScriptHookV Update Checker
Checks the installed version of the ScriptHookV plugin against the latest version online, and updates it if necessary.

## Features
- Gets game folder from registry.
- Fetches local versions directly from files.
- Deletes old plugin if GTA has been updated, but the plugin has not yet been updated in order to not break GTA.
- Logs to file by default.

## Disclaimer
This script could have been cleaner and nicer from a code perspective, but I wanted a fast, reliable, portable single-file solution without many dependencies. So, the script tries to do as much as possible itself. You should not need to modify it in order to make it work for you, but keep in mind that although it works totally fine for me, it might not work for you at all, or it might even destroy something. So, use this on your own risk.

## Dependencies
PowerShell 7. At least it has been tested with that version. It does not run with PowerShell 1.0, which you shouldn't use anyway. It might run with an PowerShell lower than version 7.0, but that hasn't been tested.

## Usage
1. Run the script.
2. You may want to create a cronjob.

## Cronjob
Use Windows' Task Scheduler and create a new task running once per day (preferably at night), and let it run this command:

```
pwsh scripthookv_update_checker.ps1
```

You will likely need to add the proper paths to the command, but basically it's just that. Save the task and you're good to go. Please don't hammer Alexander's website by constantly checking for a new version. Once per day is more than enough.
