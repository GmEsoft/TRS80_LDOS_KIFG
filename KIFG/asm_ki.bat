@echo off
set NAME=KIFG
set ZMAC=zmac\zmac
%ZMAC% %NAME%.asm -o Release\%NAME%.cmd -o %NAME%.lst -o %NAME%.bds -c -g --mras
if errorlevel 1 pause && goto :eof
pushd Release
move %NAME%.CMD KI.DVR
popd
move %NAME%.BDS KI.BDS
move %NAME%.LST KI.LST
::run_kifr
