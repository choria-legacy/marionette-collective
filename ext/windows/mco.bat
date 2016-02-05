@echo off
SETLOCAL
call "%~dp0environment.bat" %0 %*

if [%CLIENT_CONFIG%] == [] (
  ruby.exe -S -- mco %*
) else (
  ruby.exe -S -- mco %* --config "%CLIENT_CONFIG%"
)
