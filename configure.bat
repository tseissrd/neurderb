@ECHO OFF
ECHO checking ruby
IF "where ruby"==0 (
	IF "%1"=="x32" (
		redist\rubyinstaller-2.7.1-1-x86.exe"
	) ELSE (
		redist\rubyinstaller-2.7.1-1-x64.exe"
	)
)
ECHO ruby installed
ECHO writing registry entries
writeregistry.bat
config.ini