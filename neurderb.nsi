; example2.nsi
;
; This script is based on example1.nsi, but it remember the directory, 
; has uninstall support and (optionally) installs start menu shortcuts.
;
; It will install example2.nsi into a directory that the user selects,

;--------------------------------
!include x64.nsh

; The name of the installer
Name "nn enabled file hosting 1.0.0"

; The file to write
OutFile "neurderb.exe"

; Request application privileges for Windows Vista
RequestExecutionLevel user

; Build Unicode installer
Unicode True

; The default installation directory
InstallDir $APPDATA\Neurderb

; Registry key to check for directory (so if you install again, it will 
; overwrite the old one automatically)
;InstallDirRegKey HKLM "Software\Neurderb" "Install_Dir"
;Function .onInit
;  SetRegView 64
;  ReadRegStr $INSTDIR HKLM Software\Neurderb "Install_Dir"
;FunctionEnd

;--------------------------------

; Pages

Page components
Page directory
Page instfiles

UninstPage uninstConfirm
UninstPage instfiles

;--------------------------------

; The stuff to install
Section "Client"

  SectionIn RO
  
  ; Set output path to the installation directory.
  SetOutPath $INSTDIR
  
  ; Put file there
  File "src\nrbClient.rb"
  File "src\nrbGet.rb"
  File "src\nrbCMSend.rb"
  File "src\Client.rb"
  File "src\Networking.rb"
  File "src\MSGCodes.rb"
  File "src\Transmission.rb"
  File "src\Task.rb"
  File "src\FS.rb"
  File "src\ssh\Ssh.rb"
  File "src\ssh\TransportLayer.rb"
  File "src\ssh\DataTypes.rb"
  File "src\ssh\MessageCodes.rb"
  File "src\ssh\Algorithms.rb"
  File "key.txt"
  File "config.ini"
  File "redist\rubyinstaller-2.7.1-1-x64.exe"
  File "redist\rubyinstaller-2.7.1-1-x86.exe"
  File "configure.bat"
  File "CMSend.bat"
  File "start_client.bat"
  File "writeregistry.bat"
  File "clearregistry.bat"
  File "cli.bat"
  CreateDirectory $INSTDIR\src
  CreateDirectory $INSTDIR\src\ssh
  CreateDirectory $INSTDIR\redist
  Rename "nrbClient.rb" "src\nrbClient.rb"
  Rename "nrbGet.rb" "src\nrbGet.rb"
  Rename "nrbCMSend.rb" "src\nrbCMSend.rb"
  Rename "Client.rb" "src\Client.rb"
  Rename "Networking.rb" "src\Networking.rb"
  Rename "MSGCodes.rb" "src\MSGCodes.rb"
  Rename "Transmission.rb" "src\Transmission.rb"
  Rename "Task.rb" "src\Task.rb"
  Rename "FS.rb" "src\FS.rb"
  Rename "Ssh.rb" "src\ssh\Ssh.rb"
  Rename "TransportLayer.rb" "src\ssh\TransportLayer.rb"
  Rename "DataTypes.rb" "src\ssh\DataTypes.rb"
  Rename "MessageCodes.rb" "src\ssh\MessageCodes.rb"
  Rename "Algorithms.rb" "src\ssh\Algorithms.rb"
  Rename "rubyinstaller-2.7.1-1-x86.exe" "redist\rubyinstaller-2.7.1-1-x86.exe"
  Rename "rubyinstaller-2.7.1-1-x64.exe" "redist\rubyinstaller-2.7.1-1-x64.exe"
  
  ; Write the installation path into the registry
  SetRegView 32
  WriteRegStr HKLM "SOFTWARE\Neurderb" "Install_Dir" "$INSTDIR"
  
  ; Write the uninstall keys for Windows
  WriteRegStr HKLM "SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\Neurderb" "DisplayName" "Neurderb Client"
  WriteRegStr HKLM "SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\Neurderb" "UninstallString" '"$INSTDIR\uninstall.exe"'
  WriteRegDWORD HKLM "SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\Neurderb" "NoModify" 1
  WriteRegDWORD HKLM "SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\Neurderb" "NoRepair" 1
  WriteUninstaller "$INSTDIR\uninstall.exe"
  
  WriteRegStr HKLM "SOFTWARE\Classes\*\shell\Neurderb" "" "send to neurderb archive"
  WriteRegStr HKLM "SOFTWARE\Classes\*\shell\Neurderb\command" "" "$\"$INSTDIR\CMsend.bat$\" $\"%1$\""
  
  Exec "$INSTDIR\configure.bat"
  
SectionEnd

; Optional section (can be disabled by the user)
;Section "Start Menu Shortcuts"

;  CreateDirectory "$SMPROGRAMS\neurderb"
;  CreateShortcut "$SMPROGRAMS\neurderb\Uninstall.lnk" "$INSTDIR\uninstall.exe" "" "$INSTDIR\uninstall.exe" 0
;  CreateShortcut "$SMPROGRAMS\neurderb\neurderb (MakeNSISW).lnk" "$INSTDIR\example2.nsi" "" "$INSTDIR\example2.nsi" 0
  
;SectionEnd

;Section "Load into explorer context menu"

;SectionEnd

;--------------------------------

; Uninstaller

Section "Uninstall"
  
  ; Remove registry keys
  SetRegView 64
  DeleteRegKey HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\Neurderb"
  DeleteRegKey HKLM SOFTWARE\Neurderb
  DeleteRegKey HKLM "SOFTWARE\Classes\*\shell\Neurderb"

  ; Remove files and uninstaller
;  Delete "$INSTDIR\*.*"
;  Delete "$INSTDIR\redist\*.*"
;  Delete "$INSTDIR\ssh\*.*"
;  RMDir /r "$INSTDIR\redist"
;  RMDir /r "$INSTDIR\ssh"
;  ExecWait "$INSTDIR\clearregistry.bat"
  RMDir /r "$INSTDIR"
;  Delete $INSTDIR\example2.nsi
;  Delete $INSTDIR\uninstall.exe

  ; Remove shortcuts, if any
  Delete "$SMPROGRAMS\Neurderb\*.*"

  ; Remove directories used
  RMDir "$SMPROGRAMS\Neurderb"

SectionEnd
