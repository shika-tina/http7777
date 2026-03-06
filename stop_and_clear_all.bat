:: 以管理員權限來執行
@echo off
echo ---刪除reg---
reg delete "HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Run" /v "MyPythonServer" /f

echo.
echo ---刪除taskschd---
schtasks /delete /tn "MyPythonServer" /f

echo.
echo ---檢查7777端口---
netstat -ano | findstr 7777

echo.
echo ---停止pythonw.exe---
taskkill /f /im pythonw.exe

echo.
echo ---停止python.exe---
taskkill /f /im python.exe

echo.
echo ---再次檢查7777端口---
netstat -ano | findstr 7777


cmd /k echo.
