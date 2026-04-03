@echo off
cd /d "%~dp0"
"%ProgramFiles%\Git\bin\bash.exe" --login -c "cd '%~dp0'; ./agent.sh list"
pause
