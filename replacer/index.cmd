@echo off
set _PATH=%~dp0
set _SCPT=index.js

if "%~1" == ""     goto NOFILE
if not exist %~s1  goto NOFILE
if exist %~s1\NUL  goto NOFILE
if "%~2" == ""     goto NOPATT


call node.exe "%_PATH%%_SCPT%" %*
goto EXIT

::----------------------------------------------

:NOFILE
  echo you need to specify an existing file.
  goto EXIT

:NOPATT
  echo Missing regex search pattern. for example: L3MrL2dt which is: ^/^\s^+^/gm ^(escaped to BASE64^).
  goto EXIT

:EXIT

:: for search pattern you can use any javascript regex
::  L1xcIi9n            is  /\\\\"/g
::  L1wiL2c=            is  /\\\"/g
::  L2EvZw==            is  /a/g
::  L2Ev                is  /a/
::  L0ZPTlQgOCwvZw==    is  /FONT 8,/g

:: for replace pattern you can use strings
::  Jw==                is  '
::  bW1tbQ==            is  mmmm
::  Rk9OVCAxNCw=        is  FONT 14,

:: you can search /^abcd(.+)xyz$/i  and replace with $1 (escape everything to base64...)  to replace the whole string with the find.  (backtrace/backtrack)