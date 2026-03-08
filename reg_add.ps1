# 將開啟 7778 端口展示 %userprofile% 的動作加到 regedit 
# 如果python從來沒存取過網路，需要先讓他存取一次
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
Write-Host "正在執行後續自動化任務..."

# 將動作加入到 regedit 當中
$registryPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run"
$name = "MyPythonServer"
$value = 'powershell.exe -WindowStyle Hidden -Command "Start-Process pythonw.exe -ArgumentList ''-c \"import sys,os;from http.server import HTTPServer,SimpleHTTPRequestHandler;os.chdir(os.environ[''''USERPROFILE'''']); sys.stdout=open(os.devnull,''''w'''');sys.stderr=open(os.devnull,''''w'''');server=HTTPServer((''''0.0.0.0'''',7778),SimpleHTTPRequestHandler);server.serve_forever()\"'' -WindowStyle Hidden"'

Set-ItemProperty -Path $registryPath -Name $name -Value $value

write-host '腳本執行成功，7778端口將在重新開機後自動建立python server' -ForegroundColor Green
read-host '按[Enter]關閉腳本'