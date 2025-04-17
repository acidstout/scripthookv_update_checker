# Grand Theft Auto V ScriptHookV Updater
Checks the installed version of the ScriptHookV plugin against the latest version online, and updates it if necessary.

## Features
- Supports GTA V Classic and Enhanced version.
- Gets game's folder from registry.
- Fetches local versions directly from files.
- Deletes old plugin if the game has been updated, but the plugin has not yet been updated in order to not break the game.
- Logs to file by default.
- Skips download if Zip file has been downloaded manually into game's folder.
- Tries to get elevated access rights, because the game's folder is restricted by default.

## Disclaimer
This script could have been cleaner and nicer from a code perspective, but I wanted a fast, reliable, portable single-file solution without many dependencies. So, the script tries to do as much as possible itself. You should not need to modify it in order to make it work for you, but keep in mind that although it works totally fine for me, it might not work for you at all, or it might even destroy something. So, use this on your own risk.

## Dependencies
Tested successfully with PowerShell 7. It might run with a version of PowerShell lower than 7.0, but that hasn't been tested. Also, for your own sake use an up-to-date version of PowerShell.

## Usage
1. Optionally set up you mail and/or ntfy.sh configuration in ScriptHookV_Updater_sample.ps1 and rename it to ScriptHookV_Updater_config.ps1
2. Run the script.
3. You may want to create a cronjob.

## How to create a cronjob
Use Windows' Task Scheduler and create a new task running once per day (preferably at night), and let it run this command:

```
pwsh -WindowStyle hidden -File .\ScriptHookV_Updater.ps1
```

You may also use this command on an elevated prompt to have the task being created for you:

```
schtasks /create /sc daily /st 16:00 /ru system /rl highest /tn "Check for ScriptHookV plugin update" /tr "'C:\Program Files\PowerShell\7\pwsh.exe' -WindowStyle hidden -File .\ScriptHookV_Updater.ps1"
```

You will likely need to specifyy proper paths in the command, but basically it's just that. Save the task and you're good to go. Please, don't hammer Alexander's website by constantly checking for a new version. Once per day is more than enough.

## Known issues
Since the game is updated automatically by the Rockstar Launcher only when you start the game, the ScriptHookV Updater is not able to notice these updates unless you run it directly after the Launcher updated the game and prior you start the actual game. There's no way for this script to work around this issue, and permanently monitoring file system changes in the game's folder is not cool. A different solution is if Alexander Blade adds automatic update capability to his plugin if it doesn't match the game's version. So, instead of showing a message that the plugin is outdated and then quitting the game, he could make the plugin to check for an update, and if none is available, then just load the game without hooking to the game. From my perspective this is the best solution. Unfortunately, the source code of his plugin is not open source, so I cannot implement it myself. What a shame!
