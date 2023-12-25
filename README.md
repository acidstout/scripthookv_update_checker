# Grand Theft Auto V ScriptHookV Update Checker
Checks the installed version of the ScriptHookV plugin against the latest version online, and updates it if necessary.

## Features
- Gets game's folder from registry.
- Fetches local versions directly from files.
- Deletes old plugin if GTA has been updated, but the plugin has not yet been updated in order to not break GTA.
- Logs to file by default.
- Skips download if Zip file has been downloaded manually into game's folder.

## Disclaimer
This script could have been cleaner and nicer from a code perspective, but I wanted a fast, reliable, portable single-file solution without many dependencies. So, the script tries to do as much as possible itself. You should not need to modify it in order to make it work for you, but keep in mind that although it works totally fine for me, it might not work for you at all, or it might even destroy something. So, use this on your own risk.

## Dependencies
Tested successfully with PowerShell 7. It might run with a version PowerShell lower than 7.0, but that hasn't been tested.

## Usage
1. Run the script.
2. You may want to create a cronjob.

## Cronjob
Use Windows' Task Scheduler and create a new task running once per day (preferably at night), and let it run this command:

```
pwsh scripthookv_update_checker.ps1
```

You will likely need to add the proper paths to the command, but basically it's just that. Save the task and you're good to go. Please don't hammer Alexander's website by constantly checking for a new version. Once per day is more than enough.

## Known issues
Since the game is updated automatically by the Rockstar Launcher only when you start the game, the ScriptHookV Update Checker is not able to notice these updates unless you run it directly after the Launcher updated the game and prior you start the actual game. There's no way for this script to work around this issue, and permanently monitoring file system changes in the game's folder is not cool. A different solution is if Alexander Blade adds automatic update capability to his plugin if it is outdated. So, instead of showing a message that the plugin is outdated and then quitting the game, he could make the plugin to check for an update, and if none is available, then just load the game without hooking to the game. From my perspective this is the best solution. Unfortunately, the source code of his plugin is not open source, so I cannot implement it myself. What a shame!