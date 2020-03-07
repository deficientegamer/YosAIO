@echo off
echo REGEDIT4>\changeName.reg
echo "">>\changeName.reg
echo [HKEY_LOCAL_MACHINE\System\CurrentControlSet\Control\ComputerName\ComputerName]>>\changeName.reg
echo "ComputerName"="%row%%comp%%Random%">>\changeName.reg
echo "">>\changeName.reg
echo [HKEY_LOCAL_MACHINE\System\CurrentControlSet\Services\VxD\VNETSUP]>>\changeName.reg
echo "ComputerName"="%row%%comp%%Random%">>\changeName.reg
echo "Comment"="Changed by clean %row%%comp%">>\changeName.reg
regedit \changeName.reg
REG DELETE HKEY_LOCAL_MACHINE\SOFTWARE\Classes\GoS /f
REM remove GOS Files. TODO: check have unlocker prompt mode and implement this for new.dll
del %AppData%\GamingOnSteroids\ADDON /F /Q
rmdir %AppData%\GamingOnSteroids\ADDON /S /Q
del %AppData%\GamingOnSteroids\LOL /F /Q
rmdir %AppData%\GamingOnSteroids\LOL /S /Q
del %AppData%\GamingOnSteroids\RL /F /Q
rmdir %AppData%\GamingOnSteroids\RL /S /Q
del %AppData%\GamingOnSteroids\LOLEXT\older.dll /F /Q
del %AppData%\GamingOnSteroids\LOLEXT\old.dll /F /Q
"C:\Program Files (x86)\IObit\IObit Unlocker\IObitUnlocker.exe" /Delete /Advanced %AppData%\GamingOnSteroids\LOLEXT\new.dll
del %APPDATA%\Microsoft\Windows\Recent /F /Q
REG DELETE HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\RunMRU /VA /F
REG DELETE HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\TypedPaths /VA /F

exit