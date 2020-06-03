@ECHO OFF
set pwd=%cd%
FOR /F "usebackq tokens=3*" %%A IN (`REG QUERY "HKEY_LOCAL_MACHINE\Software\Neurderb" /v Install_Dir`) DO (
set appdir=%%A %%B
)
FOR /F "usebackq tokens=3*" %%A IN (`REG QUERY "HKEY_LOCAL_MACHINE\Software\Wow6432Node\Neurderb" /v Install_Dir`) DO (
set appdir=%%A %%B
)
cd "%appdir%/src"
ruby nrbGet.rb neurderb.exe "%pwd%/neurderb.exe" 5dd747c198927d7c1dc5a0f877f1f41a8801fca5