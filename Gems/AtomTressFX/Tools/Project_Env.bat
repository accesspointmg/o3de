@echo off

REM 
REM Copyright (c) Contributors to the Open 3D Engine Project.
REM For complete copyright and license terms please see the LICENSE at the root of this distribution.
REM
REM SPDX-License-Identifier: Apache-2.0 OR MIT
REM
REM

:: Sets up local project env for AtomTressFX

:: Store current dir
%~d0
cd %~dp0
PUSHD %~dp0

:: Put you project env vars and overrides here

:: chanhe the relative path up to dev
set DEV_REL_PATH=../..
set ABS_PATH=%~dp0

CD /D ..
set O3DE_PROJECT_PATH=%CD%
for %%a in (%CD%) do set O3DE_PROJECT=%%~na

echo.
echo _____________________________________________________________________
echo.
echo ~    %O3DE_PROJECT% Project Environment ...
echo _____________________________________________________________________
echo.

:: for this tool environment and it's assets this Gem is the Maya project
echo     O3DE_PROJECT = %O3DE_PROJECT%
:: this Gem is the Maya project path
echo     O3DE_PROJECT_PATH = %O3DE_PROJECT_PATH%

:: Change to root Lumberyard dev dir
CD /D %O3DE_PROJECT_PATH%\%DEV_REL_PATH%
set O3DE_DEV=%CD%
echo     O3DE_DEV = %O3DE_DEV%

:: Override the default maya version
set MAYA_VERSION=2020
echo     MAYA_VERSION = %MAYA_VERSION%

:: now runt the DCCsi env
CALL %O3DE_DEV%\Gems\AtomLyIntegration\TechnicalArt\DccScriptingInterface\Launchers\Windows\Env_Maya.bat

rem :: Constant Vars (Global)
rem SET O3DEPY_GDEBUG=0
rem echo     O3DEPY_GDEBUG = %O3DEPY_GDEBUG%
rem SET O3DEPY_DEV_MODE=0
rem echo     O3DEPY_DEV_MODE = %O3DEPY_DEV_MODE%
rem SET O3DEPY_DEBUGGER=WING
rem echo     O3DEPY_DEBUGGER = %O3DEPY_DEBUGGER%

:: DCCsi Maya plugins access
:: set DCCSI_MAYA_PLUG_IN_PATH=%DCCSI_SDK_MAYA_PATH%\plugins
:: add plug-in path to AtomTressFX
set TRESSFX_PLUG_IN_PATH=%O3DE_PROJECT_PATH%\Tools\Maya
:: also attached to maya's built-it env var
set MAYA_PLUG_IN_PATH=%TRESSFX_PLUG_IN_PATH%;%MAYA_PLUG_IN_PATH%
echo     MAYA_PLUG_IN_PATH = %MAYA_PLUG_IN_PATH%

:: Restore original directory
popd

:: Change to root dir
CD /D %ABS_PATH%

:: if the user has set up a custom env call it
IF EXIST "%~dp0User_Env.bat" CALL %~dp0User_Env.bat

GOTO END_OF_FILE

:: Return to starting directory
POPD

:END_OF_FILE