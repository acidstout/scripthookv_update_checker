#
# ScriptHookV Updater for Grand Theft Auto V
#
# Requires PowerShell 7.
#
# @author: nrekow
# @version: 1.2.4.5
#

# Disable those red error messages in case of errors, because we use Try & Catch everywhere.
# $ErrorActionPreference = "Stop"

param([switch]$elevated)

# Change folder to script directory, because elevation changes folder to C:\Windows\System32 by default, which we don't want.
Set-Location -LiteralPath $PSScriptRoot


# Check if we have elevated access rights.
#
# Return Boolean
#
Function Test-Admin {
    $currentUser = New-Object Security.Principal.WindowsPrincipal $([Security.Principal.WindowsIdentity]::GetCurrent())
    $currentUser.IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)
}


# Either write into the console or into the log file,
# depending on the $QuietMode setting.
#
# Param String $logstring
#
Function LogWrite([string]$Log_String) {
	# Get location and name of current script.
	$Script_Name = (Get-Item $PSCommandPath).Basename
	$Script_Log = "$PSScriptRoot\$Script_Name.log"

	If ($script:QuietMode -eq $false) {
		Write-Output "$Log_String`r`n"
	} else {
		$Timestamp = (Get-Date).ToString('yyyy-MM-dd HH:mm:ss')
		Add-content $Script_Log -value ("[" + $Timestamp + "] " + $Log_String)
	}
}


# Send a mail upon successful update.
#
# Param String $version
#
Function Send-ToEmail([string]$version) {
    $message = New-Object Net.Mail.MailMessage
    $message.From = "ScriptHookV Updater <$script:MailUsername>"
    $message.To.Add($script:MailRecipient)
    $message.Subject = "ScriptHookV Updater"
    $message.Body = "Latest ScriptHookV $version has been successfully installed. You can now use all scripts and plugins in GTA V again."
 
    $smtp = new-object Net.Mail.SmtpClient($script:MailServer, $script:MailPort)
    $smtp.EnableSSL = $true
    $smtp.Credentials = New-Object System.Net.NetworkCredential($script:MailUsername, $script:MailPassword)
    $smtp.send($message)
    LogWrite "Mail sent." 
}


# Gets latest user-agent of installed standard browsers.
#
# Return String
#  
Function Get-UserAgent() {
	# Fallback User-Agent.
	$User_Agent = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36'
	
	# Try to get version of installed browser in order to set up-to-date User-Agent.
	# Check for Edge
	$Edge_Version = '0.0'
	$Edge_Exe = Get-ItemPropertyValue 'HKLM:\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\App Paths\\msedge.exe' "(default)"
	if (Test-Path $Edge_Exe) {
		$Edge_Version = (Get-Item $Edge_Exe).VersionInfo.ProductVersion
		$Edge_Agent = -join('Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/', $Edge_Version, ' Safari/537.36 Edg/', $Edge_Version)
	}
	
	# Check for Chrome
	$Chrome_Version = '0.0'
	$Chrome_Exe = Get-ItemPropertyValue -Path 'HKLM:\\SOFTWARE\\Microsoft\Windows\\CurrentVersion\\App Paths\\chrome.exe' -Name '(default)'
	if (Test-Path $Chrome_Exe) {
		$Chrome_Version = (Get-Item $Chrome_Exe).VersionInfo.ProductVersion
		$Chrome_Agent = -join('Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/', $Chrome_Version, ' Safari/537.36')
	}
	
	# Check for Firefox
	$Firefox_Version = '0.0'
	$Firefox_Registry_Path = 'HKLM:\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\App Paths\\firefox.exe'
	if (Test-Path $Firefox_Registry_Path) {
		$Firefox_Exe = Get-ItemPropertyValue -Path $Firefox_Registry_Path -Name '(default)'
		if (Test-Path $Firefox_Exe) {
			$Firefox_Version = (Get-Item $Firefox_Exe).VersionInfo.ProductVersion
			$Firefox_Agent = -join('Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:', $Firefox_Version, ') Gecko/20100101 Firefox/', $Firefox_Version)
		}
	}
	
	# Keep note of found browsers and versions in a hashtable.
	$Browser_Versions = @{'Edge'=$Edge_Version; 'Chrome'=$Chrome_Version; 'Firefox'=$Firefox_Version}
	
	# PowerShell does not allow sorting hashtables by value, so we need to work around this issue.
	# Define temporary values. Those variables will contain the name and version of the browser with the highest version.
	$TempVersion = '0.0'
	$TempName = ''
	
	# Iterate over our hashtable.
	foreach ($key in $Browser_Versions.GetEnumerator()) {
		# Compare temporary version with current version.
		if ($TempVersion -lt $($key.Value)) {
			# Set temporary name and version accordingly.
			$TempName = $($key.Name)
			$TempVersion = $($key.Value)
		}
	}
	
	# Build the name of our variable which hold the appropriate user-agent.
	$TempName = -join($TempName, '_Agent')
	
	# Set our User-Agent to the respective value if we received a proper version number.
	if ($TempVersion -ne '0.0') {
		$User_Agent = (Get-Variable -name $TempName).Value
	}

	return $User_Agetnt
}


# Check if we have elevated access rights.
If ((Test-Admin) -eq $false)  {
    If ($elevated) {
        # Tried to elevate, did not work, aborting.
		LogWrite "Could not elevate access rights."
    } Else {
    	LogWrite "Trying to elevate access rights."
        Start-Process 'C:\Program Files\PowerShell\7\pwsh.exe' -WindowStyle hidden -Verb RunAs -ArgumentList ('-noprofile -file "{0}" -elevated' -f ($myinvocation.MyCommand.Definition))
    }
    Exit
}

LogWrite "Got elevated access rights."

# Check if configuration file exists and load it.
$ConfigFile = "$PSScriptRoot\$((Get-Item $PSCommandPath).Basename)_config.ps1"
If ([System.IO.File]::Exists($ConfigFile)) {
	. $ConfigFile
} Else {
	# Fallback values if not config file has been set up.
	$script:QuietMode = $true
	$script:UseMail = $false
	$script:NotifyURL = $false
}

Add-Type -AssemblyName Microsoft.PowerShell.Commands.Utility
Add-Type -Assembly System.IO.Compression.FileSystem

# Get location from registry where GTA V is installed.
Try {
	$Game_Folder = Get-ItemPropertyValue -Path 'HKLM:\SOFTWARE\WOW6432Node\Rockstar Games\Grand Theft Auto V\' -Name 'InstallFolder'
} Catch {
	LogWrite "Grand Theft Auto V does not seem to be installed."
	Exit
}

# Set ScriptHookV URLs and define fallback version for cases where ScriptHookV is not installed.
$ScriptHookV_Version = '0.0'
$ScriptHookV_URL = 'http://www.dev-c.com/gtav/scripthookv/'
$ScriptHookV_Download_URL = 'http://www.dev-c.com/files/ScriptHookV_<VERSION>.zip'

# Get latest user-agent from installed standard browsers.
$User_Agent = Get-UserAgent()

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
		$ScriptHookV_Version = '0.0'
	}
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
	$SHV_Session = New-Object Microsoft.PowerShell.Commands.WebRequestSession
	$req = Invoke-WebRequest -Method GET -Uri $ScriptHookV_URL -Headers $Headers -SessionVariable $SHV_Session
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
If ($script:QuietMode -eq $false) {
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
				LogWrite "Info $($Status_Code): Downloaded latest version from website $ScriptHookV_Download_URL."
			} Catch {
				$Status_Code = [int]$_.Exception.Response.StatusCode
				LogWrite "Error $($Status_Code): Could not download latest version from website $ScriptHookV_Download_URL."
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
				$zip.Entries.Name
				Write-Host $Destination_File
				
				If ($Found_File = $zip.Entries.Where({ $_.Name -eq 'ScriptHookV.dll' }, 'First')) {
					LogWrite "Found ScriptHookV.dll in Zip file."
					# Set destination path of file to extract
					$DLL_Destination_File = Join-Path $Game_Folder $Found_File.Name
					
					# Extract the file.
					Try {
						[IO.Compression.ZipFileExtensions]::ExtractToFile($Found_File[0], $DLL_Destination_File)
					} Catch {
						LogWrite "Could not unpack downloaded Zip file."
					}
				} Else {
					LogWrite "Zip file does not seem to contain ScriptHookV.dll."
				}
			} Catch {
				LogWrite "Could not unpack Zip archive."
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
			
			If ($script:UseMail -eq $true) {
				Try {
					# Send mail to inform about latest update.
					Send-ToEmail -version $ScriptHookV_Remote_Version
				} Catch {
					LogWrite "Could not send mail about update."
				}
			}
			
			if ($script:NotifyURL -ne $false) {
				Try {
					$payload = "Latest ScriptHookV $ScriptHookV_Remote_Version has been successfully installed."
					$resp = Invoke-WebRequest -Method POST -Uri $script:NotifyURL -Body $payload
					$Status_Code = $resp.StatusCode
					LogWrite "Info $($Status_Code): Sent notfication."
				} Catch {
					LogWrite "Could not reach $script:NotifyURL"
				}
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
