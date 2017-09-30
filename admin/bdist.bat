@echo on

FOR /F "usebackq tokens=3*" %%A IN (`REG QUERY "HKEY_LOCAL_MACHINE\SOFTWARE\Wow6432Node\Microsoft\VisualStudio\12.0" /v InstallDir`) DO (
    set appdir=%%A %%B
)

set OUTDIR=%1
shift

:top
if "%1" == "" goto :end

set INDIR=dist
if "%1" == "unicorn" set INDIR=bindings\python\dist
if "%1" == "capstone" set INDIR=bindings\python\dist
if "%1" == "angr-z3" set INDIR=src\api\python\dist

cd %1

:: 				# These paths are hardcoded for Audrey's laptop
if exist build rmdir /Q /S build
cmd /c call "%appdir%..\..\VC\vcvarsall.bat" x64 ^&^& call D:\Programs\Python2x64\Python.exe setup.py bdist_wheel
if exist build rmdir /Q /S build
cmd /c call "%appdir%..\..\VC\vcvarsall.bat" x86 ^&^& call D:\Programs\Python2\Python.exe setup.py bdist_wheel
copy %INDIR%\* ..\%OUTDIR%

:continue
cd ..
shift
goto :top

:end
