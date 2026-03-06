# 將動作加到工作排程器當中，使每次開啟電腦都自動執行命令，存取7777端口開啟伺服器展示C槽，需要管理員權限允許 python 存取網路、taskschd 和 管理員powershell 變更裝置
# 1.找到python位置
$fullPath = (where.exe python)[0]

# AppData\Local\Microsoft\WindowsApps\python.exe 有時候並不是真的 python.exe 無法使用(它是 python 從 Microsoft store 下載時預設的路徑，即使電腦裡沒有任何 python，他也會出現 where python 的結果當中)
if ($fullPath -like "*\WindowsApps\*") {
    Write-Host "偵測到 Microsoft Store 版 Python ($fullPath)" -ForegroundColor Red
}

# 2. 判斷邏輯：如果路徑包含空格 (通常是 Program Files)，就直接用 "python" 
# 反之則使用完整路徑 (因為 AppData/Local/... 通常沒有空格)
# (在系統啟動階段，會找不到安裝在 AppData 下的 python 除非手動指定路徑，與位於 Program Files 的不同)
if ($fullPath -like "* *") {
    $pypath = "python.exe"
} else {
    $pypath = $fullPath
}

# 如果python從來沒存取過網路，需要先讓他存取一次
python.exe -c "import os; from http.server import HTTPServer, SimpleHTTPRequestHandler; os.chdir(os.environ['USERPROFILE']); print('activating testing ctrl + c to out...'); server=HTTPServer(('0.0.0.0',7777), SimpleHTTPRequestHandler); server.serve_forever()"

# 放進排程器裡的字數是有上限的(所以把程式縮減了)
$code = "import sys,os;from http.server import HTTPServer as h,SimpleHTTPRequestHandler as s;os.chdir(''C:/'');sys.stdout=open(os.devnull,''w'');h((''0.0.0.0'',7777),s).serve_forever()"

# 3. 將任務加進排程器裡
Start-Process schtasks -ArgumentList "/create /tn `"MyPythonServer`" /tr `"\`"$pypath\`" -c \`"$code\`"`" /sc onstart /ru system /f" -Verb RunAs

# 4. 立即修改該任務的電源設定 (允許非AC電源時仍然啟動，且換成電池時不停止)
Start-Process powershell -ArgumentList "-Command `"Set-ScheduledTask -TaskName 'MyPythonServer' -Settings (New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries)`"" -Verb RunAs
