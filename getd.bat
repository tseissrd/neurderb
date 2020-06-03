FOR /F "usebackq tokens=3*" %%A IN (`REG QUERY "HKEY_LOCAL_MACHINE\Software\Neurderb" /ve`) DO (
    set appdir=%%A %%B
    )
ECHO %appdir%