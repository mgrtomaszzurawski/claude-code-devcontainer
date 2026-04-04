@echo off
cd /d "%~dp0"
echo ============================================
echo  Claude Code Image Upgrade
echo ============================================
echo.
echo This rebuilds the image with latest Claude Code.
echo Running pods are NOT affected until restart.
echo Auth, chat history, and theme are preserved.
echo.
pause
"%ProgramFiles%\Git\bin\bash.exe" --login -c "cd '%~dp0'; ./agent.sh upgrade"
pause
