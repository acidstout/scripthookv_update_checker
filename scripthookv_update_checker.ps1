#
# ScriptHookV Update Checker for Grand Theft Auto V
#
# Successfully tested on PowerShell 7.
# Does NOT work on PowerShell 1.0.
#
# @author: nrekow
# @version: 1.1
#

# Disable those red error messages in case of errors, because we use Try & Catch everywhere.
$ErrorActionPreference = "Stop"

# If TRUE no output will be printed. Instead errors will be logged into a file.
$QuietMode = $true

# Define fallback version for cases where ScriptHookV is not installed.
$Fallback_ScriptHookV_Version = '0.0'

# Get location and name of current script.
# Used to create a logfile of the same name.
$scriptName = (Get-Item $PSCommandPath).Basename
$scriptLog = "$PSScriptRoot\$scriptName.log"


# Either write into the console or into the log file,
# depending on the $QuietMode setting.
#
# Param String $logstring
#
Function LogWrite {
	Param ([string]$logstring)
	If ($QuietMode -eq $false) {
		Write-Output "$logstring`r`n"
	} else {
		$Timestamp = (Get-Date).ToString('yyyy-MM-dd HH:mm:ss')
		Add-content $scriptLog -value ("[" + $Timestamp + "] " + $logstring)
	}
}


# Get location from registry where GTA V is installed.
Try {
	$Game_Folder = Get-ItemPropertyValue -Path 'HKLM:\SOFTWARE\WOW6432Node\Rockstar Games\Grand Theft Auto V\' -Name 'InstallFolder'
} Catch {
	LogWrite "Grand Theft Auto V does not seem to be installed."
	Exit
}

# Set ScriptHookV URLs.
$ScriptHookV_URL = 'http://www.dev-c.com/gtav/scripthookv/'
$ScriptHookV_Download_URL = 'http://www.dev-c.com/files/ScriptHookV_<VERSION>.zip'

# Get installed ScriptHookV version.
Try {
	$ScriptHookV_Version = (Get-Item ($Game_Folder + '\ScriptHookV.dll')).VersionInfo.FileVersion
} Catch {
	# ScriptHookV plugin is not installed.
	$ScriptHookV_Version = $Fallback_ScriptHookV_Version
}

# Get installed game version.
Try {
	$Game_Version = (Get-Item ($Game_Folder + '\GTA5.exe')).VersionInfo.FileVersion
} Catch {
	LogWrite "Could not find GTA5.exe in folder $Game_Folder."
	Exit
}

# Get ScriptHookV version from website.
Try {
	$req = Invoke-WebRequest -Method GET -Uri $ScriptHookV_URL
	$HTML = New-Object -Com "HTMLFile"
	[string]$htmlBody = $req.Content
	$HTML.write([ref]$htmlBody) # This is throws an error in PowerShell 1.0.
	$filter = $HTML.getElementById('tfhover')
	$ScriptHookV_Remote_Version = $filter.innerText.split("`r`n")[1].Replace('Versionv', '')
} Catch {
	LogWrite "Could not fetch latest ScriptHookV plugin version from website $ScriptHookV_URL."
	Exit
}

# Show version found.
If ($QuietMode -eq $false) {
	Write-Output "`r`nScriptHookV Update Checker`r`n"
	Write-Output "Installed game version: $Game_Version"
	Write-Output "Installed plugin version: $ScriptHookV_Version"
	Write-Output "Latest plugin version: $ScriptHookV_Remote_Version`r`n"
}

If ([System.Version]$ScriptHookV_Version -lt [System.Version]$Game_Version) {
	# Installed ScriptHookV version is older than game version.
	LogWrite "ScriptHookV is outdated or not installed."
	
	# Check if outdated ScriptHookV plugin needs to be deleted from game folder.
	if ([System.IO.File]::Exists($Game_Folder + '\ScriptHookV.dll')) {
		Try {
			# Delete outdated ScriptHookV plugin.
			Remove-Item ($Game_Folder + '\ScriptHookV.dll') -Force
		} Catch {
			LogWrite "Could not delete outdated ScriptHookV plugin. You should remove it manually."
			Exit
		}
	}
	
	If ([System.Version]$ScriptHookV_Remote_Version -ge [System.Version]$Game_Version) {
		# Remote version is newer or equal than game version.
		LogWrite "Downloading latest version ..."
		
		$ScriptHookV_Download_URL =	$ScriptHookV_Download_URL.Replace('<VERSION>', $ScriptHookV_Remote_Version)
		$Destination_File = ($Game_Folder + '\' + $(Split-Path -Path $ScriptHookV_Download_URL -Leaf))
		
		Try {
			# Download new ScriptHookV zip-file.
			Invoke-WebRequest $ScriptHookV_Download_URL -Headers @{"Referrer"=$ScriptHookV_URL} -OutFile $Destination_File
		} Catch {
			LogWrite "Could not download latest version from website $ScriptHookV_Download_URL."
			Exit
		}
		
		# Unzip the DLL from the downloaded file into the game's folder.
		LogWrite "Unpacking new version ..."
		
		Try {
			Add-Type -Assembly System.IO.Compression.FileSystem
			$zip = [IO.Compression.ZipFile]::OpenRead($Destination_File)
			$zip.Entries | where {$_.Name -like 'ScriptHookV.dll'} | foreach {[System.IO.Compression.ZipFileExtensions]::ExtractToFile($_, $Game_Folder, $true)}
			$zip.Dispose()
		} Catch {
			LogWrite "Could not unpack ScriptHookV plugin into game folder."
			Exit
		}
		
		Try {
			# Delete zip file after unpacking DLL.
			Remove-Item $Destination_File -Force
		} Catch {
			LogWrite "Could not delete downloaded zip-file. You may need to remove it manually."
		}
		
		LogWrite "Done!"
	} Else {
		# If the remote version is older than the game version, then there's no updated plugin, yet.
		LogWrite "No update available, yet."
	}
} Else {
	LogWrite "No update needed."
}
