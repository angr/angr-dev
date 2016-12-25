cd %ANGR_REPO% || exit /b 1
if exist tests (
  nosetests -v --nologcapture tests || exit /b 1
) else if exist test.py (
  nosetests -v --nologcapture test.py || exit /b 1
) else (
  echo 'Unknown test configuration!' && exit /b 1
)
