if not exist angr git clone https://github.com/angr/angr.git || goto :error
if not exist simuvex git clone https://github.com/angr/simuvex.git || goto :error
if not exist claripy git clone https://github.com/angr/claripy.git || goto :error
if not exist cle git clone https://github.com/angr/cle.git || goto :error
if not exist pyvex git clone https://github.com/angr/pyvex.git || goto :error
if not exist vex git clone https://github.com/angr/vex.git || goto :error
if not exist archinfo git clone https://github.com/angr/archinfo.git || goto :error
if not exist angr-doc git clone https://github.com/angr/angr-doc.git || goto :error
if not exist binaries git clone https://github.com/angr/binaries.git || goto :error
if not exist wheels git clone https://github.com/angr/wheels.git || goto :error

if not "%APPVEYOR%"=="" (
    cd %APPVEYOR_BUILD_FOLDER%
    set url=
    set branch=
    for /f "usebackq tokens=2 skip=1" %%a in (`git remote -v`) do set url=%%a
    for /f "usebackq tokens=2" %%a in (`git branch`) do set branch=%%a
    echo Appveyor status: testing %branch% from %url%
    :: if "%url:~0,24%"=="https://github.com/angr/"
    
    :: call git_all.bat remote add pr_remote https://github.com/%APPVEYOR_REPO_NAME%.git
    :: call git_all.bat fetch pr_remote
    call git_all.bat checkout %1
) else if not "%1" == "" (
    call git_all.bat checkout %1
)

pip install wheels\capstone-4.0.0-py2-none-win32.whl
pip install wheels\unicorn-1.0.0-py2.py3-none-win32.whl

pip install -e .\archinfo || goto :error
pip install -e .\pyvex || goto :error
pip install -e .\cle || goto :error
pip install -e .\claripy || goto :error
pip install -e .\simuvex || goto :error
pip install -e .\angr || goto :error

pip install nose monkeyhex ipdb || goto :error

echo "Developement install success!"
exit /b 0

:error
echo "Developement install failed!"
exit /b 1
