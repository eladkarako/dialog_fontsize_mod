@echo off


::--------------------------------------------------------------
:: NOTES:
::    this may help you:
::      https://github.com/eladkarako/dialog_fontsize_mod
::      https://github.com/eladkarako/reshacker
::      https://github.com/eladkarako/rc
::      https://github.com/eladkarako/Windows-SDK-7.1
::      https://github.com/eladkarako/replacer
::
::    using BASE64:
::      L1xcIi9n            is    /\\"/g
::      Jw==                is    '
::      L0ZPTlQgOCwvZw==    is    /FONT 8,/g
::      Rk9OVCAxMiw=        is    FONT 12,
::--------------------------------------------------------------


echo.
echo ----------------------------------------------------------
echo -  font_size_increase
echo -  You can drag and drop binary files ^(exe, dll,...^) over,
echo -  and it will automaticly modify the DIALOG resources,
echo -  increasing the font-size from 8pt to 14pt,
echo -  it will then create a modified version of your file.
echo -  
echo -  It started as a way of increasing the size
echo -  of CCleaner's UI, to look nicely on high DPI-screens.
echo -  
echo -  Using reshacker, MS resource-compiler ^(from WinSDK 7.1^)
echo -  a nodejs program I've made to handle regexp search-replace
echo -  and a collection of symbols definitions I've collected from
echo -  WinUser.h, WinNT.h, WinGDI.h, WinDef.h
echo -  and CommCtrl.h ^(from WinSDK 7.1^)
echo -  
echo -  If you find yourself having problems using rc.exe
echo -  and you see symbol not found error, download github.com/eladkarako/Windows-SDK-7.1/
echo -  and use Locate32 (for example) too look for text inside of the .h files,
echo -  looking for the definitions missing, add it to the defines.rc .
echo -  
echo -  There are no dependencies or downloads required,
echo -  everything is supplied ^(yes even exe files...^)
echo -  
echo -  You probably want to "unblock" and check ON the 
echo -  compatibility "run as admin" for each of the exe files.
echo -  
echo -                       Enjoy!
echo -                       EladKarako. June 2017.
echo -------------------------------------------------------
echo.


::well defined home-folder (to avoid a mix-up when running the script from another folder, this essentially workaround "working folder" changes CMD quirk when running from another location... :/ ).
set CURRENT_PATH=%~dp0


::tools to use
set TOOL_RESHACKER="%CURRENT_PATH%reshacker\reshacker.exe"
set TOOL_REPLACER="%CURRENT_PATH%replacer\index.cmd"
set TOOL_DEFINES="%CURRENT_PATH%defines.rc"
set TOOL_RC="%CURRENT_PATH%rc\x64\RC.Exe"


::overkill - (note: but apparently needed...) convery tool's path to absolute and short (8.3 old dos format) to make things less buggy. also removes " wrapping (not needed now)
for /f %%a in ("%TOOL_RESHACKER%")do (set "TOOL_RESHACKER=%%~fsa"  )
for /f %%a in ("%TOOL_REPLACER%")do  (set "TOOL_REPLACER=%%~fsa"   )
for /f %%a in ("%TOOL_DEFINES%")do   (set "TOOL_DEFINES=%%~fsa"    )
for /f %%a in ("%TOOL_RC%")do        (set "TOOL_RC=%%~fsa"         )


::verify tools exist.
if not exist %TOOL_RESHACKER%        goto NOTOOL_RESHACKER
if not exist %TOOL_REPLACER%         goto NOTOOL_REPLACER
if not exist %TOOL_DEFINES%          goto NOTOOL_DEFINES
if not exist %TOOL_RC%               goto NOTOOL_RC


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
del /f /q %FILE_OUTPUT%    2>nul >nul
del /f /q %FILE_TEMP%      2>nul >nul
del /f /q %FILE_RC%        2>nul >nul
del /f /q %FILE_RES%       2>nul >nul


::extract .rc of all DIALOG resources into one file (text).
call %TOOL_RESHACKER% -extract "%FILE_INPUT%,%FILE_TEMP%,DIALOG,,"
echo DEBUG:  extracting DIALOG-resources in RC ^(text^) mode.
if not exist %FILE_TEMP%  goto NORCTEMP
echo done.
echo.


::search-replace file-content using nodejs (base64 of regex)
echo DEBUG:  search-replace the text in the RC file, fixing stuff ^(uses NodeJS^).
call %TOOL_REPLACER% %FILE_TEMP% "L1xcIi9n"         "Jw=="
call %TOOL_REPLACER% %FILE_TEMP% "L0ZPTlQgOCwvZw==" "Rk9OVCAxMiw="
echo done.
echo.


::prepend symbols-define lines (from Windows-SDK).
echo DEBUG:  prepend common symbol-definitions from Windows-SDK to the .rc file.
type %TOOL_DEFINES%            >%FILE_RC%
type %FILE_TEMP%              >>%FILE_RC%
if not exist %FILE_RC%         goto NORC
echo done.
echo.


::cleanup
del /f /q %FILE_TEMP%         2>nul >nul


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

echo -------------------------------------------------------
echo -  ALL DONE.
echo -  ^(feel free to delete the .rc and .res files^)
echo -  Your modify file:
echo -  %FILE_OUTPUT%
echo -                       Enjoy!
echo -                       EladKarako. June 2017.
echo -------------------------------------------------------
echo.


goto EXIT


::--------------------------------------------------------------


:NOTOOL_RESHACKER
  echo.
  echo Error:   reshacker.exe is missing.
  goto EXIT


:NOTOOL_REPLACER
  echo.
  echo Error:   replacer - index.cmd is missing.
  goto EXIT


:NOTOOL_DEFINES
  echo.
  echo Error:   defines.rc is missing.
  goto EXIT


:NOTOOL_RC
  echo.
  echo Error:   rc.exe is missing.
  goto EXIT


:NOFILEIN
  echo.
  echo Error:   Missing path to file ^(ie: "C:\mypath\myfile.exe"^)
  goto EXIT


:NORCTEMP
  echo.
  echo Error:   reshacker.exe seems to failed to extract RC resource file from %FILE_INPUT%.
  goto EXIT


:NORC
  echo.
  echo Error:   could not join %TOOL_DEFINES% and  %FILE_TEMP% to generate %FILE_RC% .
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

