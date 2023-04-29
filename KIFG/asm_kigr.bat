@echo off
set NAME=KIFG
set ZMAC=zmac\zmac
%ZMAC% %NAME%.asm -P2=1 -o Release\%NAME%.cmd -o %NAME%.lst -o %NAME%.bds -c -g --mras
if errorlevel 1 pause && goto :eof
pushd Release
move %NAME%.CMD KIGR.DVR
popd
move %NAME%.BDS KIGR.BDS
move %NAME%.LST KIGR.LST
::run_kigr
