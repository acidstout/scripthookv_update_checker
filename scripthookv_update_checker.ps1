#
# ScriptHookV Update Checker for Grand Theft Auto V
#
# Requires PowerShell 7.
#
# @author: nrekow
# @version: 1.2.2
#

# Disable those red error messages in case of errors, because we use Try & Catch everywhere.
# $ErrorActionPreference = "Stop"

# Define fallback version for cases where ScriptHookV is not installed.
$Fallback_ScriptHookV_Version = '0.0'

# Get location and name of current script.
# Used to create a logfile of the same name.
$Script_Name = (Get-Item $PSCommandPath).Basename
$script:Script_Log = "$PSScriptRoot\$Script_Name.log"

# If TRUE no output will be printed. Instead errors will be logged into a file.
$script:Quiet_Mode = $true

Add-Type -AssemblyName Microsoft.PowerShell.Commands.Utility
Add-Type -Assembly System.IO.Compression.FileSystem


# Either write into the console or into the log file,
# depending on the $QuietMode setting.
#
# Param String $logstring
#
Function LogWrite {
	Param ([string]$Log_String)
	If ($script:Quiet_Mode -eq $false) {
		Write-Output "$Log_String`r`n"
	} else {
		$Timestamp = (Get-Date).ToString('yyyy-MM-dd HH:mm:ss')
		Add-content $script:Script_Log -value ("[" + $Timestamp + "] " + $Log_String)
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
$User_Agent = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36'
$Headers = @{
	'Referer' = $ScriptHookV_URL
	'User-Agent' = $User_Agent
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
	$req = Invoke-WebRequest -Method GET -Uri $ScriptHookV_URL -Headers $Headers -SessionVariable SHV_Session
	$HTML = New-Object -Com "HTMLFile"
	[string]$HtmlBody = $req.Content

	[void]($HtmlBody -match "\/files\/ScriptHookV_[0-9\.]+\.zip")
	$Link = $Matches[0]
	$ScriptHookV_Remote_Version = $Link.Substring(19)
	$ScriptHookV_Remote_Version = $ScriptHookV_Remote_Version.Substring(0, [int]$ScriptHookV_Remote_Version.IndexOf('.zip'))
} Catch {
	LogWrite "Could not fetch latest ScriptHookV plugin version from website $ScriptHookV_URL."
	Exit
}

# Show version found.
If ($Quiet_Mode -eq $false) {
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
				$resp = Invoke-WebRequest -Method GET -Uri $ScriptHookV_Download_URL -Headers $Headers -OutFile $($Destination_File) -WebSession $SHV_Session
				$Status_Code = $resp.StatusCode
			} Catch {
				$Status_Code = [int]$_.Exception.Response.StatusCode
				LogWrite "Error $($Status_Code) : Could not download latest version from website $ScriptHookV_Download_URL."
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
				If ($Found_File = $zip.Entries.Where({ $_.Name -eq 'ScriptHookV.dll' }, 'First')) {
					# Set destination path of file to extract
					$Destination_File = Join-Path $Game_Folder $Found_File.Name
					
					# Extract the file.
					[IO.Compression.ZipFileExtensions]::ExtractToFile($Found_File[0], $Destination_File)
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
