tasklist | FIND "emacs" >nul
if errorlevel 1 (start /B C:\ProgramData\chocolatey\lib\Emacs\tools\emacs\bin\runemacs.exe --daemon) else (start /B C:\ProgramData\chocolatey\lib\Emacs\tools\emacs\bin\emacsclient.exe -n -c -a "")