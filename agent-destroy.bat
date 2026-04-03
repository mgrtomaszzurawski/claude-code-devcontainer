@echo off
cd /d "%~dp0"

:loop
cls
"%ProgramFiles%\Git\bin\bash.exe" --login -c "cd '%~dp0'; ./agent.sh list"
echo.
set /p NAME="Agent name to destroy (or 'q' to quit): "
if "%NAME%"=="q" exit /b
"%ProgramFiles%\Git\bin\bash.exe" --login -c "cd '%~dp0'; ./agent.sh destroy %NAME%"
timeout /t 1 /nobreak >nul
goto loop
