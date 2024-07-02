:: MIT License
:: Copyright (c) 2024 NightmareSan
:: 
:: Permission is hereby granted, free of charge, to any person obtaining a copy
:: of this software and associated documentation files (the "Software"), to deal
:: in the Software without restriction, including without limitation the rights
:: to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
:: copies of the Software, and to permit persons to whom the Software is
:: furnished to do so, subject to the following conditions:
:: 
:: The above copyright notice and this permission notice shall be included in all
:: copies or substantial portions of the Software.
:: 
:: THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
:: IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
:: FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
:: AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
:: LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
:: OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
:: SOFTWARE.

:: Code by Nightmare
@echo off
setlocal EnableDelayedExpansion

::Configuration Sections
set "saltydownloadlink=https://gaming.v10networks.com/saltychat/download/stable" # Required Saltychat download Link
set "teamspeakdownloadlink=https://files.teamspeak-services.com/releases/client/3.6.2/TeamSpeak3-Client-win64-3.6.2.exe" # Required Teamspeak Version download Link
set "teamspeakversion="3.6.2.0"" # Which Teamspeak Version is being used?
set "saltyversion=3.1.2" # Which Saltychat version is being used?

:: DO NOT TOUCH ANYTHING BELOW
set "saltydnsto=127.0.0.1"
set "saltydnsfrom=lh.v10.network" 

:: For Color Coding
for /F "tokens=1,2 delims=#" %%a in ('"prompt #$H#$E# & echo on & for %%b in (1) do rem"') do (
  set "DEL=%%a"
)

:: 32/64 Bit detection
IF "%PROCESSOR_ARCHITECTURE%" EQU "amd64" (
>nul 2>&1 "%SYSTEMROOT%\SysWOW64\cacls.exe" "%SYSTEMROOT%\SysWOW64\config\system"
) ELSE (
>nul 2>&1 "%SYSTEMROOT%\system32\cacls.exe" "%SYSTEMROOT%\system32\config\system"
)

:: Request Admin Priviliges
REM --> If error flag set, we do not have admin.
if '%errorlevel%' NEQ '0' (
call :ColorText "4" "Adminrechte nicht vorhanden, Administratorrechte werden angefragt..."
goto UACPrompt
) else ( goto gotAdmin )

:UACPrompt
echo Set UAC = CreateObject^("Shell.Application"^) > "%temp%\getadmin.vbs"
set params= %*
echo UAC.ShellExecute "cmd.exe", "/c ""%~s0"" %params:"=""%", "", "runas", 1 >> "%temp%\getadmin.vbs"

"%temp%\getadmin.vbs"
del "%temp%\getadmin.vbs"
exit /B

:gotAdmin
call :ColorText A "Administratorrechte vorhanden. Fortsetzen"

::Find Downloads Folder
:DOWNLOADS
for /f "tokens=2*" %%D in ('reg query "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Shell Folders" /v "{374DE290-123F-4565-9164-39C4925E467B}" ^| find "{374DE290-123F-4565-9164-39C4925E467B}"') do (
    set "DownloadsFolder=%%E"
)
cls

:: Set Teamspeak Path
:TSPATH
for /f "tokens=2*" %%A in ('reg query "HKEY_CLASSES_ROOT\ts3file\shell\open\command" /ve 2^>nul ^| find /i "ts3client_win64.exe"') do (
    set "ts3Path=%%B"
)
set "ts3RawPath=!ts3Path:ts3client_win64.exe" "%%1"=!"

:: Get TS3 Version
:TSVERSION
for /f "tokens=*" %%D in ('powershell.exe -Command "$FilePath='!ts3Path:~0,-5!'; Write-Host ((New-Object -COMObject Shell.Application).NameSpace((Split-Path -Parent -Path $FilePath))).ParseName((Split-Path -Leaf -Path $FilePath)).ExtendedProperty('Fileversion')"') do (
    set "fileVersion=%%D"
)
cls

echo                              ____           _   ___       __    __                          
echo                             / __ )__  __   / ^| / (_)___ _/ /_  / /_____ ___  ____ _________ 
echo                            / __  / / / /  /  ^|/ / / __ ^`/ __ \/ __/ __ ^`__ \/ __ ^`/ ___/ _ \
echo                           / /_/ / /_/ /  / /^|  / / /_/ / / / / /_/ / / / / / /_/ / /  /  __/
echo                          /_____/\__, /  /_/ ^|_/_/\__, /_/ /_/\__/_/ /_/ /_/\__,_/_/   \___/ 
echo                                 /____/           /____/                                     
echo.
echo.
::Default DLL Path for SaltyChat.DLL
set "dllPath=!APPDATA!\TS3Client\plugins\SaltyChat_win64.dll"

IF EXIST "!dllPath!" (
    set "saltyinstall=YES"
    goto :DLL
) ELSE (
    set "saltyinstall=NO"
    goto :NDLL
)


:: Read SaltyChat Version
:DLL
for /f %%V in ('powershell -command "[Reflection.Assembly]::LoadFrom('%dllPath%').CreateInstance('SaltyChat.Model.PluginState').Version"') do (
    set "batchVariable=%%V"
)


:: TS3 Version Check
:NDLL
if defined ts3Path (
    if "!fileVersion!" == !teamspeakversion! (
        call :ColorText "6" "TS3 Installation wurde gefunden. Es wird die aktuellste Version !fileVersion:~0,-2! verwendet."
        echo.
        call :SALTYVERSIONCHECK
    ) else (
        call :ColorText "6" "TS3 Installation wurde gefunden aber es wird eine alte Version !fileVersion! verwendet."
        echo.
        :: Erstelle den Ordner "Salty_Setup" im Downloads-Ordner
        call :SETUPDIR
        call :TSDOWNLOAD
        call :SALTYVERSIONCHECK
        echo.
    )
) else (
    call :ColorText "6" "TS3 Installation wurde nicht gefunden. Die neuste TS3 & Saltychat Version wird heruntergeladen"
    echo...
    :: Erstelle den Ordner "Salty_Setup" im Downloads-Ordner
    call :SETUPDIR
    call :TSDOWNLOAD
    call :SALTYDOWNLOAD
    echo.
)

goto :SALTYMOVEFIX
::Salty Version Check
:SALTYVERSIONCHECK
if !saltyinstall! == YES (
            if !batchVariable! == !saltyversion! (
                call :ColorText "6" "Saltychat Installation wurde gefunden. Es wird die aktuellste Version !batchVariable! verwendet."
                echo.
            ) else (
                call :ColorText "6" "Saltychat Installation wurde gefunden aber es wird eine alte Version !batchVariable! verwendet."
                echo.
                echo.
                :: Erstelle den Ordner "Salty_Setup" im Downloads-Ordner
                call :SETUPDIR
                call :SALTYDOWNLOAD
            )
        ) else (
            call :SETUPDIR
            call :SALTYDOWNLOAD
        )
goto :eof


:: Create Folder
:SETUPDIR
call :ColorText "6" "Ordner SaltySetup wird in Downloads erstellt"
echo.
echo.
md "%DownloadsFolder%\Salty_Setup " 2>nul
goto :eof

:: Download & Install Salty Chat
:SALTYDOWNLOAD
call :ColorText "6" "Saltychat wird heruntergeladen und anschliessend gestartet"
echo.
call :ColorText "9" "Bitte schliesse die Saltychat Installation ab"
echo.
curl -# -o "%DownloadsFolder%\Salty_Setup\SaltyChat.ts3_plugin" !saltydownloadlink!
echo.
call :CHECKTSOPEN
!ts3RawPath!package_inst.exe" "%DownloadsFolder%\Salty_Setup\SaltyChat.ts3_plugin"
goto :eof

:: Download & Install Teamspeak
:TSDOWNLOAD
call :ColorText "6" "Teamspeak wird heruntergeladen und anschliessend gestartet"
echo.
call :ColorText "9" "Bitte schliesse die Teamspeak Installation ab"
echo.
curl -# -o "%DownloadsFolder%\Salty_Setup\TeamSpeak3-Client-win64.exe" !teamspeakdownloadlink!
echo.
call :CHECKTSOPEN
"%DownloadsFolder%\Salty_Setup\TeamSpeak3-Client-win64.exe"
for /f "tokens=2*" %%A in ('reg query "HKEY_CLASSES_ROOT\ts3file\shell\open\command" /ve ^| find /i "ts3client_win64.exe"') do (
    set "ts3Path=%%B"
)
set "ts3RawPath=!ts3Path:ts3client_win64.exe" "%%1"=!"
::set "ts3RawPath=!ts3Path:~0,-25!"
::echo "RAWPATH" !ts3RawPath!
goto :eof


:: Close Teamspeak if Process open
:CHECKTSOPEN
tasklist /FI "IMAGENAME eq ts3client_win64.exe" 2>NUL | find /I /N "ts3client_win64.exe">NUL
if "%ERRORLEVEL%"=="0" (
    call :ColorText "6" "Teamspeak ist noch offen und wird gleich geschlossen."
    echo.
    timeout /t 2 /nobreak >nul
    taskkill /F /IM ts3client_win64.exe
)
goto :eof


:: Put DNS into .hosts File on Windows
:SALTYMOVEFIX
nslookup !saltydnsfrom! > "%temp%\nslookup_output.txt" 2>&1
find /i "Address:  !saltydnsto!" "%temp%\nslookup_output.txt" > nul
if not %errorlevel% equ 0 (
    echo.
    call :ColorText "6" "Die Hosts-Datei wird angepasst und der DNS hinterlegt."
    echo.
    (
        echo.
        echo # ----------------- Saltychat DNS -----------------
        echo !saltydnsto!  !saltydnsfrom!
        echo.
    ) >> "%windir%\system32\drivers\etc\hosts"
) else (
    echo.
)

:: Finish Installation
:HF
call :ColorText "9" "Es sollte alles mit Saltychat funktionieren. Falls nicht, komm gerne in den Support."
del "%temp%\nslookup_output.txt" 2>nul
rmdir /s /q "%DownloadsFolder%\Salty_Setup" 2>nul
echo.
echo Das Fenster wird in 7 Sekunden geschlossen und alle heruntergeladenen Dateien werden geloescht...
timeout /t 7 /nobreak >nul
exit /b

:ColorText
<nul set /p ".=%DEL%" > "%~2"
findstr /v /a:%1 /R "^$" "%~2" nul
del "%~2" > nul 2>&1
goto :eof

endlocal
