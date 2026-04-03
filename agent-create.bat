@echo off
cd /d "%~dp0"
set /p NAME="Agent name: "
"%ProgramFiles%\Git\bin\bash.exe" --login -c "cd '%~dp0'; ./agent.sh create %NAME%"
timeout /t 1 /nobreak >nul
explorer "%~dp0agent-shells\%NAME%"