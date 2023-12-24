#
# ScriptHookV Update Checker for Grand Theft Auto V
#
# Requires PowerShell 7.
#
# @author: nrekow
# @version: 1.2
#

# Disable those red error messages in case of errors, because we use Try & Catch everywhere.
# $ErrorActionPreference = "Stop"

# If TRUE no output will be printed. Instead errors will be logged into a file.
$QuietMode = $false

# Define fallback version for cases where ScriptHookV is not installed.
$Fallback_ScriptHookV_Version = '0.0'

# Get location and name of current script.
# Used to create a logfile of the same name.
$scriptName = (Get-Item $PSCommandPath).Basename
$scriptLog = "$PSScriptRoot\$scriptName.log"

Add-Type -AssemblyName Microsoft.PowerShell.Commands.Utility
Add-Type -Assembly System.IO.Compression.FileSystem

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
$userAgent = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36'
$headers = @{
	'Referer' = $ScriptHookV_URL
	'User-Agent' = $userAgent
}

# Get installed ScriptHookV version.
If ([System.IO.File]::Exists($Game_Folder + '\ScriptHookV.dll')) {
	Try {
		$ScriptHookV_Version = (Get-Item ($Game_Folder + '\ScriptHookV.dll')).VersionInfo.FileVersion
	} Catch {
		# ScriptHookV plugin is not installed.
		LogWrite 'Could not read version from ScriptHookV.dll file. Using fallback version.'
		$ScriptHookV_Version = $Fallback_ScriptHookV_Version
	}
} Else {
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
	$req = Invoke-WebRequest -Method GET -Uri $ScriptHookV_URL -Headers $headers -SessionVariable shv_session
	$HTML = New-Object -Com "HTMLFile"
	[string]$htmlBody = $req.Content

	[void]($htmlBody -match "\/files\/ScriptHookV_[0-9\.]+\.zip")
	$link = $matches[0]
	$ScriptHookV_Remote_Version = $link.Substring(19)
	$ScriptHookV_Remote_Version = $ScriptHookV_Remote_Version.Substring(0, [int]$ScriptHookV_Remote_Version.IndexOf('.zip'))
	
	# $HTML.write([ref]$htmlBody) # This is throws an error in PowerShell 1.0.
	# $filter = $HTML.getElementById('tfhover')
	# $ScriptHookV_Remote_Version = $filter.innerText.split("`r`n")[1].Replace('Versionv', '')
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
		$ScriptHookV_Download_URL =	$ScriptHookV_Download_URL.Replace('<VERSION>', $ScriptHookV_Remote_Version)
		$Destination_File = ($Game_Folder + '\' + $(Split-Path -Path $ScriptHookV_Download_URL -Leaf))

		# Check if Zip file has already been downloaded.
		If (-not([System.IO.File]::Exists($($Destination_File)))) {
			LogWrite "Downloading latest version ..."
			Try {
				# Download new ScriptHookV Zip file.
				$resp = Invoke-WebRequest -Method GET -Uri $ScriptHookV_Download_URL -Headers $headers -OutFile $($Destination_File) -WebSession $shv_session
				$statusCode = $resp.StatusCode
			} Catch {
				$statusCode = [int]$_.Exception.Response.StatusCode
				LogWrite "Error $($statusCode) : Could not download latest version from website $ScriptHookV_Download_URL."
			}
		} Else {
			LogWrite "Destination file already exists. Skipping download."
		}
		
		# Unzip the DLL from the downloaded file into the game's folder.
		If ([System.IO.File]::Exists($($Destination_File))) {
			LogWrite "Unpacking new version ..."
			$zip = [IO.Compression.ZipFile]::OpenRead($Destination_File)
			Try {
				# Find specific file in Zip archive.
				If ($foundFile = $zip.Entries.Where({ $_.Name -eq 'ScriptHookV.dll' }, 'First')) {
					# Set destination path of file to extract
					$destinationFile = Join-Path $Game_Folder $foundFile.Name
					
					# Extract the file.
					[IO.Compression.ZipFileExtensions]::ExtractToFile($foundFile[0], $destinationFile)
				} Else {
					LogWrite "Zip file does not seem to contain ScriptHookV.dll."
				}
			} Finally {
				# Close the Zip so the file will be unlocked again.
				If ($zip) {
					$zip.Dispose()
				}
			}
			
			Try {
				# Delete zip file after unpacking DLL.
				Remove-Item $Destination_File -Force
			} Catch {
				LogWrite "Could not delete downloaded Zip file. You may need to remove it manually."
			}
			
			LogWrite "Done!"
		} Else {
			# If download failed for whatever reason and there's also no manually downloaded Zip file in the game's folder.
			LogWrite "Could not find Zip file to extract."
		}
	} Else {
		# If the remote version is older than the game version, then there's no updated plugin, yet.
		LogWrite "No update available, yet."
	}
} Else {
	LogWrite "No update needed."
}
