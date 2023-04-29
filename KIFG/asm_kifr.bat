@echo off
set NAME=KIFG
set ZMAC=zmac\zmac
%ZMAC% %NAME%.asm -P1=1 -o Release\%NAME%.cmd -o %NAME%.lst -o %NAME%.bds -c -g --mras
if errorlevel 1 pause && goto :eof
pushd Release
move %NAME%.CMD KIFR.DVR
popd
move %NAME%.BDS KIFR.BDS
move %NAME%.LST KIFR.LST
::run_kifr
