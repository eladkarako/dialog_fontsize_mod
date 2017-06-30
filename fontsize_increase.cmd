::@echo off


::well defined home-folder (to avoid a mix-up when running the script from another folder, this essentially workaround "working folder" changes CMD quirk when running from another location... :/ ).
set CURRENT_PATH=%~dp0


::tools to use
set TOOL_RESHACKER="%CURRENT_PATH%reshacker\reshacker.exe"
set TOOL_REPLACER="%CURRENT_PATH%replacer\index.cmd"
set TOOL_DEFINES="%CURRENT_PATH%defines.rc"
set TOOL_RC="%CURRENT_PATH%rc\x64\RC.Exe"


::overkill - convery tool's path to absolute and short (8.3 old dos format) to make things less buggy. also removes " wrapping (not needed now)
for /f %%a in ("%TOOL_RESHACKER%")do (set "TOOL_RESHACKER=%%~fsa"  )
for /f %%a in ("%TOOL_REPLACER%")do  (set "TOOL_REPLACER=%%~fsa"   )
for /f %%a in ("%TOOL_DEFINES%")do   (set "TOOL_DEFINES=%%~fsa"    )
for /f %%a in ("%TOOL_RC%")do        (set "TOOL_RC=%%~fsa"         )


::input file name will be used to generate temporary RC, RES files and the final modified one with "_MOD" suffix. here the "overkill" is not needed, the input file format has similar/same way of working...
set FILE_INPUT="%~s1"
set FILE_RC="%~d1%~p1%~n1_DIALOGs.rc"
set FILE_TEMP="%~d1%~p1%~n1_TEMP.rc"
set FILE_RES="%~d1%~p1%~n1_DIALOGs.res"
set FILE_OUTPUT="%~d1%~p1%~n1_MOD%~x1"


::overkill - OPTIONAL - apply following fix. it will make sure path always absolute (full) from possibly a relative one.
for /f %%a in ("%FILE_INPUT%")do (set "FILE_INPUT=%%~fsa"  )
for /f %%a in ("%FILE_RC%")do    (set "FILE_RC=%%~fsa"     )
for /f %%a in ("%FILE_TEMP%")do  (set "FILE_TEMP=%%~fsa"   )
for /f %%a in ("%FILE_RES%")do   (set "FILE_RES=%%~fsa"    )


::verify existing target.
if ["%~s1" == ""]          goto NOFILEIN
if not exist "%~s1"        goto NOFILEIN
if not exist %FILE_INPUT%  goto NOFILEIN


::cleanup (although not really needed, since everything will overwrite if needed...).
del /f /q %FILE_OUTPUT%    
del /f /q %FILE_TEMP%      
del /f /q %FILE_RC%        
del /f /q %FILE_RES%       


::extract .rc of all DIALOG resources into one file (text).
call %TOOL_RESHACKER% -extract "%FILE_INPUT%,%FILE_TEMP%,DIALOG,,"
echo DEBUG:  extracting DIALOG-resources in RC ^(text^) mode.
if not exist %FILE_TEMP%  goto NORCTEMP
echo done.
echo.


::search-replace file-content using nodejs (base64 of regex) - first is \" to '  second is FONT 8, to FONT 12
echo DEBUG:  search-replace the text in the RC file, fixing stuff ^(uses NodeJS^).
call %TOOL_REPLACER% %FILE_TEMP% "L1xcIi9n"         "Jw=="
call %TOOL_REPLACER% %FILE_TEMP% "L0ZPTlQgOCwvZw==" "Rk9OVCAxMiw="
echo done.
echo.


::prepend symbols-define lines (from Windows-SDK).
echo DEBUG:  adding DIALOG-related symbol-define-lines from Windows-SDK to the head of the RC file.
type %TOOL_DEFINES%            >%FILE_RC%
type %FILE_TEMP%              >>%FILE_RC%
del /f /q %FILE_TEMP%         
echo done.
echo.


::compile filename.rc to filename.res (on errors add missing define lines to defines.rc)
echo DEBUG:  compile RC to RES ^(using Microsoft Resource Compiler - rc.exe^).
call %TOOL_RC% %FILE_RC%  
if not exist %FILE_RES%   goto NORES
echo done.
echo.


::modify
echo DEBUG:  modify DIALOG-resources in %FILE_INPUT% ^(using reshacker.exe^).
call %TOOL_RESHACKER% -modify "%FILE_INPUT%,%FILE_OUTPUT%,%FILE_RES%,DIALOG,,"
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
:NOTOOL_RESHACKER
  echo.
  echo Error:   reshacker.exe is missing.
  goto EXIT


:NOTOOL_RC
  echo.
  echo Error:   rc.exe is missing.
  goto EXIT


:NOTOOL_REPLACER
  echo.
  echo Error:   replacer - index.cmd is missing.
  goto EXIT


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
  pause 

