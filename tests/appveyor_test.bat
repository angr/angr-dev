set result=0

call env\scripts\activate.bat

:top
if "%1" == "" goto :end
echo RUNNING TESTS FOR %1
cd %1 || exit /b 1

set NOSE_OPTIONS=-v --nologcapture --processes 1 --process-restartworker --process-timeout 600 --with-flaky --max-runs 3 -A speed!='slow'

if exist tests (
  nosetests %NOSE_OPTIONS% tests || set result=1 && goto :continue
) else if exist test.py (
  nosetests %NOSE_OPTIONS% test.py || set result=1 && goto :continue
) else (
  echo Unknown test configuration && set result=1 && goto :continue
)

:continue
cd ..
shift
echo ------------------------------------------
goto :top

:end
exit /b %result%
