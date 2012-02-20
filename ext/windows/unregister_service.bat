@echo off

SETLOCAL

call "%~dp0environment.bat" %0 %*

%RUBY% -S -- service_manager.rb --uninstall
