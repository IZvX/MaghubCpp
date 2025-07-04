@echo off
setlocal enabledelayedexpansion

:: PowerShell GUI prompt function template
set PS_PROMPT=Add-Type -AssemblyName PresentationFramework; $res = [System.Windows.MessageBox]::Show('%1','MagnetHub Installer','YesNo','Question'); if($res -eq 'Yes'){exit 0}else{exit 1}

:: Prompt to start installation
powershell -Command "%PS_PROMPT: %1=Do you want to start the MagnetHub installation?%"

if errorlevel 1 (
    echo Installation cancelled.
    pause
    exit /b
)

:: Create temp folder for downloads
set TEMP_DIR=%TEMP%\MagnetHubInstaller
if not exist "%TEMP_DIR%" mkdir "%TEMP_DIR%"
cd /d "%TEMP_DIR%"

:: Download source ZIP (replace URL)
echo Downloading source ZIP...
powershell -Command "Invoke-WebRequest -Uri 'https://yourdomain.com/source.zip' -OutFile 'source.zip'"
if errorlevel 1 (
    echo ERROR: Failed to download source.zip.
    pause
    exit /b
)

:: Download server.zip (replace URL)
echo Downloading server.zip...
powershell -Command "Invoke-WebRequest -Uri 'https://yourdomain.com/server.zip' -OutFile 'server.zip'"
if errorlevel 1 (
    echo ERROR: Failed to download server.zip.
    pause
    exit /b
)

:: Extract server.zip to Documents/MagnetHub/server
echo Extracting server files...
powershell -Command "Expand-Archive -Path 'server.zip' -DestinationPath ([Environment]::GetFolderPath('MyDocuments') + '\MagnetHub\server') -Force"
if errorlevel 1 (
    echo ERROR: Failed to extract server.zip.
    pause
    exit /b
)

del server.zip

:: Extract source.zip
echo Extracting source code...
powershell -Command "Expand-Archive -Path 'source.zip' -DestinationPath '%TEMP_DIR%\QtAppSource' -Force"
if errorlevel 1 (
    echo ERROR: Failed to extract source.zip.
    pause
    exit /b
)

del source.zip

:: Install dependencies (example with Chocolatey)
echo Installing dependencies...
choco install qt5 -y
choco install mpv -y

if errorlevel 1 (
    echo WARNING: Some dependencies may have failed to install.
)

:: Build project
cd "%TEMP_DIR%\QtAppSource\repo-main"
qmake
if errorlevel 1 (
    echo qmake failed.
    pause
    exit /b
)
mingw32-make
if errorlevel 1 (
    echo Build failed.
    pause
    exit /b
)
cd /d "%TEMP_DIR%"

:: Ask if keep source code
powershell -Command "%PS_PROMPT: %1=Do you want to keep the source code after installation?%"

if errorlevel 1 (
    echo Removing source...
    rmdir /s /q QtAppSource
)

:: Ask to create desktop shortcut
powershell -Command "%PS_PROMPT: %1=Create desktop shortcut?%"

if errorlevel 0 (
    echo Creating desktop shortcut...
    powershell -Command "$s=(New-Object -COM WScript.Shell).CreateShortcut([Environment]::GetFolderPath('Desktop') + '\MagnetHub.lnk'); $s.TargetPath='%TEMP_DIR%\QtAppSource\repo-main\yourapp.exe'; $s.Save()"
)

:: Ask to create start menu shortcut
powershell -Command "%PS_PROMPT: %1=Create Start Menu shortcut?%"

if errorlevel 0 (
    echo Creating Start Menu shortcut...
    powershell -Command "$s=(New-Object -COM WScript.Shell).CreateShortcut([Environment]::GetFolderPath('StartMenu') + '\Programs\MagnetHub.lnk'); $s.TargetPath='%TEMP_DIR%\QtAppSource\repo-main\yourapp.exe'; $s.Save()"
)

echo Installation complete.
pause
endlocal
exit /b
