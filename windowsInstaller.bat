@echo off
setlocal enabledelayedexpansion

:: PowerShell GUI prompt function template
set PS_PROMPT=Add-Type -AssemblyFramework; $res = [System.Windows.MessageBox]::Show('%1','MagnetHub Installer','YesNo','Question'); if($res -eq 'Yes'){exit 0}else{exit 1}

:: Prompt to start installation
powershell -Command "%PS_PROMPT: %1=Do you want to start the MagnetHub installation?%"

if errorlevel 1 (
    echo Installation cancelled.
    pause
    exit /b
)

:: Check for admin rights (required for Chocolatey install & system-wide changes)
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo ERROR: Please run this installer as Administrator.
    pause
    exit /b 1
)

:: Check if Chocolatey is installed
where choco >nul 2>&1
if errorlevel 1 (
    echo Chocolatey not found. Installing Chocolatey...
    powershell -NoProfile -InputFormat None -ExecutionPolicy Bypass -Command ^
        "Set-ExecutionPolicy Bypass -Scope Process -Force; ^
        [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; ^
        iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))"
    if errorlevel 1 (
        echo ERROR: Chocolatey installation failed.
        pause
        exit /b 1
    )
    echo Chocolatey installed successfully.
    :: Refresh PATH so choco is immediately usable
    set "PATH=%PATH%;%ALLUSERSPROFILE%\chocolatey\bin"
)

:: Install required dependencies
echo Installing Qt, mpv, and build tools...
choco install qt5 -y
choco install mpv -y
choco install mingw -y

if errorlevel 1 (
    echo WARNING: Some dependencies may have failed to install.
    echo Please check the output above.
)

:: Create temp folder for downloads
set TEMP_DIR=%TEMP%\MagnetHubInstaller
if not exist "%TEMP_DIR%" mkdir "%TEMP_DIR%"
cd /d "%TEMP_DIR%"

:: Download source ZIP (replace URL)
echo Downloading source ZIP...
powershell -Command "Invoke-WebRequest -Uri 'https://drive.google.com/uc?export=download&id=17eEuMdWWFDEqFsRdn1djZfwAfNUq7Kct' -OutFile 'source.zip'"
if errorlevel 1 (
    echo ERROR: Failed to download source.zip.
    pause
    exit /b
)

:: Download server.zip (replace URL)
echo Downloading server.zip...
powershell -Command "Invoke-WebRequest -Uri 'https://drive.google.com/uc?export=download&id=17eEuMdWWFDEqFsRdn1djZfwAfNUq7Kct' -OutFile 'server.zip'"
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

:: Build project
echo Building the Qt project...
cd "%TEMP_DIR%\QtAppSource\repo-main"

qmake
if errorlevel 1 (
    echo ERROR: qmake failed. Make sure Qt installed correctly.
    pause
    exit /b
)

mingw32-make
if errorlevel 1 (
    echo ERROR: Build failed. Check your build environment.
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
