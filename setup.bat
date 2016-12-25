git clone https://github.com/angr/angr.git || goto :error
git clone https://github.com/angr/simuvex.git || goto :error
git clone https://github.com/angr/claripy.git || goto :error
git clone https://github.com/angr/cle.git || goto :error
git clone https://github.com/angr/pyvex.git || goto :error
git clone https://github.com/angr/vex.git || goto :error
git clone https://github.com/angr/archinfo.git || goto :error
git clone https://github.com/angr/capstone.git || goto :error
git clone https://github.com/angr/angr-doc.git || goto :error

if ("%1" == "") goto :nocheckout
git_all.bat checkout %1
:nocheckout

pip install -e .\capstone || goto :error
pip install -e .\archinfo || goto :error
pip install -e .\pyvex || goto :error
pip install -e .\cle || goto :error
pip install -e .\claripy || goto :error
pip install -e .\simuvex || goto :error
pip install -e .\angr || goto :error

pip install nose || goto :error

echo "Developement install success!"
exit /b 0

:error
echo "Developement install failed!"
exit /b 1
