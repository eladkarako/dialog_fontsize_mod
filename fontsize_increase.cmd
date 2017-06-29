@echo off
set FILE_INPUT  ="%~s1"
set FILE_OUTPUT ="%~d1%~p1%~n1_MOD%~x1"

set FILE_RC     ="%~d1%~p1%~n1_DIALOGs.rc"
set FILE_TEMP   ="%~d1%~p1%~n1_TEMP.rc"
set FILE_RES    ="%~d1%~p1%~n1_DIALOGs.res"


::verify existing target.
if ["%~s1" == ""]    goto NOFILEIN;
if not exist "%~s1"  goto NOFILEIN;


::cleanup (although not needed).
del /f /q %FILE_OUTPUT%   2>nul >nul
del /f /q %FILE_TEMP%     2>nul >nul
del /f /q %FILE_RC%       2>nul >nul
del /f /q %FILE_RES%      2>nul >nul


::extract .rc of all DIALOG resources into one file (text).
call reshacker\reshacker.exe -extract "%FILE_INPUT%,%FILE_TEMP%,DIALOG,,"
echo DEBUG:  extracting DIALOG-resources in RC ^(text^) mode.
if not exist %FILE_TEMP%  goto NORCTEMP
echo done.
echo.


::search-replace file-content using nodejs (base64 of regex) - first is \" to '  second is FONT 8, to FONT 12
echo DEBUG:  search-replace the text in the RC file, fixing stuff ^(uses NodeJS^).
call replacer\index.cmd %FILE_TEMP% "L1xcIi9n"         "Jw=="
call replacer\index.cmd %FILE_TEMP% "L0ZPTlQgOCwvZw==" "Rk9OVCAxMiw="
echo done.
echo.


::prepend symbols-define lines (from Windows-SDK).
echo DEBUG:  adding DIALOG-related symbol-define-lines from Windows-SDK to the head of the RC file.
type "defines.rc"             >%FILE_RC%
type %FILE_TEMP%              >>%FILE_RC%
del /f /q %FILE_TEMP%         2>nul >nul
echo done.
echo.


::compile filename.rc to filename.res (on errors add missing define lines to defines.rc)
echo DEBUG:  compile RC to RES ^(using Microsoft Resource Compiler - rc.exe^).
call rc\x64\RC.Exe %FILE_RC%  2>nul >nul
if not exist %FILE_RES%  goto NORES
echo done.
echo.


::modify
echo DEBUG:  modify DIALOG-resources in %FILE_INPUT% ^(using reshacker.exe^).
call reshacker\reshacker.exe -modify "%FILE_INPUT%,%FILE_OUTPUT%,%FILE_RES%,DIALOG,,"
if not exist %FILE_OUTPUT%  goto NOFILEOUT
echo done.
echo.


echo all done.
echo You may delete the .rc and .res files (or keep-them for debug-purposes).
echo The modify file is %FILE_OUTPUT% . -- Enjoy!
echo EladKarako. June 2017.
echo.
echo.


goto EXIT

::--------------------------------------------------------------
:NOFILEIN
  echo.
  echo Error:   Missing path to file ^(ie: "C:\mypath\myfile.exe"^)
  goto EXIT

:NORCTEMP
  echo.
  echo Error:   reshacker.exe seems to failed to extract RC resource file from %FILE_INPUT%.
  goto EXIT

:NORES
  echo.
  echo Error:   rc.exe seems to failed to compile RC to RES.
  echo          add more define-lines to defines.rc ^(look in WinUser.h, WinNT.h, WinGDI.h, WinDef.h or CommCtrl.h^).
  goto EXIT

:NOFILEOUT
  echo.
  echo Error:   reshacker.exe seems to failed to modify %FILE_INPUT%, since there was no %FILE_OUTPUT% generated.
  echo          look under reshacker folder for the log-file, it might help...
  goto EXIT

:EXIT
  echo.
  echo ^(Press any key to quit...^)
  echo.
  pause 2>nul >nul
