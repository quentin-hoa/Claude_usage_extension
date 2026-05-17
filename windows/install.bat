@echo off
echo ==> Installing Claude Usage Stats for Windows...

:: Check Python
python --version >nul 2>&1
if %errorlevel% neq 0 (
    echo ERROR: Python not found. Install from https://python.org
    pause
    exit /b 1
)

:: Check Claude credentials
set CREDS=%USERPROFILE%\.claude\.credentials.json
if not exist "%CREDS%" (
    echo ERROR: Claude credentials not found at %CREDS%
    echo        Install Claude Code CLI ^(https://claude.ai/code^) and log in first.
    pause
    exit /b 1
)

:: Install Python dependencies
echo ==> Installing Python dependencies...
pip install -r "%~dp0requirements.txt"

:: Copy shared script
set SHARED_DIR=%USERPROFILE%\.local\share\claude-usage-stats
if not exist "%SHARED_DIR%" mkdir "%SHARED_DIR%"
copy /y "%~dp0..\shared\fetch_usage.py" "%SHARED_DIR%\fetch_usage.py"

:: Create startup shortcut in shell:startup
set STARTUP=%APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup
set VBS_PATH=%STARTUP%\claude-usage-tray.vbs

echo Set WshShell = CreateObject("WScript.Shell") > "%VBS_PATH%"
echo WshShell.Run "pythonw ""%~dp0claude_usage_tray.py""", 0, False >> "%VBS_PATH%"

echo.
echo ==> Done! Claude Usage tray will start automatically on login.
echo     To start now: pythonw "%~dp0claude_usage_tray.py"
pause
