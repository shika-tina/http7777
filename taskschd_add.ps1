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

# 3. 如果python從來沒存取過網路，需要先讓他存取一次
# 3-1. 定義要執行的 Python 內容 (使用單引號避免路徑斜線問題)
$pythonCommand = "import os; from http.server import HTTPServer, SimpleHTTPRequestHandler; os.chdir('C:/'); print('Server started on port 7777...'); HTTPServer(('0.0.0.0', 7777), SimpleHTTPRequestHandler).serve_forever()"

Write-Host "--------------------------------------------"
Write-Host "Python 測試 Server 啟動中..."
Write-Host "請在瀏覽器輸入 http://localhost:7777 進行測試"
Write-Host "測試完畢後，請按 [任意鍵] 關閉 Server 並繼續後續腳本..." -ForegroundColor Yellow
Write-Host "--------------------------------------------"

# 3-2. 啟動背景工作執行 Python
$job = Start-Job -ScriptBlock { python.exe -c $using:pythonCommand }

# 3-3. 暫停腳本，直到使用者按下「任意按鍵」
# (這能避開 Ctrl+C 導致整個視窗關閉的問題)
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")

# 3-4. 關閉並清理背景程序
Write-Host "`n正在停止 Server..." -ForegroundColor Gray
Stop-Job $job
Remove-Job $job

# 3-5. 後續腳本內容
Write-Host "Server 已成功關閉！" -ForegroundColor Green

# 放進排程器裡的字數是有上限的(所以把程式縮減了)
$code = "import sys,os;from http.server import HTTPServer as h,SimpleHTTPRequestHandler as s;os.chdir(''C:/'');sys.stdout=open(os.devnull,''w'');h((''0.0.0.0'',7777),s).serve_forever()"

# 4. 將任務加進排程器裡
Write-Host "加入工作排程器..."
Start-Process schtasks -ArgumentList "/create /tn `"MyPythonServer`" /tr `"\`"$pypath\`" -c \`"$code\`"`" /sc onstart /ru system /f" -Verb RunAs

# 5. 立即修改該任務的電源設定 (允許非AC電源時仍然啟動，且換成電池時不停止)
Write-Host "修改工作任務電源設定..."
Start-Process powershell -ArgumentList "-Command `"Set-ScheduledTask -TaskName 'MyPythonServer' -Settings (New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries)`"" -Verb RunAs

# 6. 以防萬一，設立windows進階防火牆對7777端口排除的設定
Write-Host "建立防火牆排除規則..."
Start-Process powershell -Verb RunAs -ArgumentList "-Command", "New-NetFirewallRule -DisplayName 'Open Port 7777' -Direction Inbound -Action Allow -Protocol TCP -LocalPort 7777"

write-host '腳本執行成功，7777端口將在重新開機後自動建立python server' -ForegroundColor Green
read-host '按[Enter]關閉腳本' 