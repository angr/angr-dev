set result=0

:top
if "%1" == "" goto :end
echo RUNNING TESTS FOR %1
cd %1 || exit /b 1

env set NOSE_PROCESS_RESTARTWORKER=1

if exist tests (
  nosetests -v --nologcapture tests || set result=1 && goto :continue
) else if exist test.py (
  nosetests -v --nologcapture test.py || set result=1 && goto :continue
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
