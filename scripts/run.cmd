@echo off
echo.
echo #############################
echo RUNNING SETUP
echo #############################
echo.
call scripts\install.cmd
call scripts\load_config.cmd
powershell -Command "Start-Process 'scripts\startup.cmd' -Verb RunAs"
call scripts\reload.cmd