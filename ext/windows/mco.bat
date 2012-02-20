@echo off

SETLOCAL

call "%~dp0environment.bat" %0 %*

%RUBY% -S -- mco %* --config "%CLIENT_CONFIG%"
