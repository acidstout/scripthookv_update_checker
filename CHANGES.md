#Changelog

1.2.5.1
- Added soft-check of PowerShell version.

1.2.5
- Added support for GTA V Enhanced.

1.2.4.7
- Moved imports to the top of the file.

1.2.4.6
- Added support for BattlEye anti-cheat crap.

1.2.4.5
- Get latest version of installed standard browsers and set highest version in User-Agent string.

1.2.4.4
- Disable mail in config sample by default to reflect fallback settings in script.

1.2.4.3
- Updated config file to support all configuration options.
- Updated order of functions, because PowerShell does not seem to find functions which are defined some lines below the actual invocation of that function.
- Updated README.md file.
- Changed license from GNUv3 to MIT.

1.2.4.2
- Added function the check for and request elevated access rights, because the GTA V game folder is restricted by default.

1.2.4.1
- Added support for ntfy.sh to send push messages upon successful update.

1.2.4
- Added option to send mail upon successful update.

1.2.3
- Got rid of fallback version variable
- Reduced amount of global variables

1.2.2
- Changed scope of variables.
- Consistent naming convention

1.2.1
- Fixed global variable definitions
- Fixed HTML parsing due to changes on the website

1.2
- Refactored method to extract Zip file.
- Skip download if Zip file already exists.
- Added user-agent and web session handling

1.1
- Try to delete outdated plugin file only if it still exists.

1.0
- Initial release.