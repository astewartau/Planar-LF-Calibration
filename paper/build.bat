@echo off
:start
call latexmk -pdf -silent
echo Done!
:pause
:goto start