@echo off
echo.
echo                 _       .-.                            
echo                :_;      : :                            
echo ,-.,-.,-. .--. .-. .--. : `-. .-..-. .--.  ,-.,-. .--. 
echo : ,. ,. :' '_.': :'  ..': .. :: :; :' .; ; : ,. :' .; :
echo :_;:_;:_;`.__.':_;`.__.':_;:_;`.__.'`.__,_;:_;:_;`._. ;
echo                                                   .-. :    

echo һ��ִ�У�����windows��ȫ����
echo ����������......

secedit /configure /db gp.sdb /cfg security.inf

::����ȱʧ�˻�
for /f "skip=4 tokens=1-3" %%i in ('net user') do (
	if "%%i"=="Administrator"  echo ���޸�Ĭ�Ϲ���Ա�˺�:%%i
	if "%%i"=="Guest"  echo ������û�:%%i
	if "%%j"=="Administrator" echo ���޸�Ĭ�Ϲ���Ա�˺�:%%j
	if "%%j"=="Guest"  echo ������û�:%%j
	if "%%k"=="Administrator" echo ���޸�Ĭ�Ϲ���Ա�˺�:%%k
	if "%%k"=="Guest"  echo ������û�:%%k
)

::����SNMP��������
set   EnableDeadGWDetect=False
for /f "skip=2 tokens=1-3" %%i in ('REG QUERY HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters') do if "%%i"=="EnableDeadGWDetect" if "%%k"=="0x0" set EnableDeadGWDetect=True

if %EnableDeadGWDetect%==False (
	REG ADD HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters /f /v EnableDeadGWDetect /t REG_DWORD /d 0 
	echo ����SNMP���������ɹ�
	rem echo �����EnableDeadGWDetect=0x0
)


::����ICMP��������
set   EnableICMPRedirect=False
for /f "skip=2 tokens=1-3" %%i in ('REG QUERY HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters') do (
	if "%%i"=="EnableICMPRedirect" if "%%k"=="0x0" set EnableICMPRedirect=True
)
if %EnableICMPRedirect%==False (
REG ADD HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters /f /v EnableICMPRedirect /t REG_DWORD /d 0
echo ����ICMP���������ɹ�
rem echo �����EnableICMPRedirect=0x0
) 

::����SYN��������
set   SynAttackProtect=False
for /f "skip=2 tokens=1-3" %%i in ('REG QUERY HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters') do (
	if "%%i"=="SynAttackProtect" if "%%k"=="0x2" set SynAttackProtect=True
)
if %SynAttackProtect%==False (
REG ADD HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters /f /v SynAttackProtect /t REG_DWORD /d 2
REG ADD HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters /f /v TcpMaxPortsExhausted /t REG_DWORD /d 5
REG ADD HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters /f /v TcpMaxHalfOpen /t REG_DWORD /d 500
REG ADD HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters /f /v TcpMaxHalfOpenRetried /t REG_DWORD /d 400
)

::����IPԴ·��
set   DisableIPSourceRouting=False
for /f "skip=2 tokens=1-3" %%i in ('REG QUERY HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters') do (
	if "%%i"=="DisableIPSourceRouting" if "%%k"=="0x1" set DisableIPSourceRouting=True
)
if %DisableIPSourceRouting%==False (
REG ADD HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters /f /v DisableIPSourceRouting /t REG_DWORD /d 1
echo ����IPԴ·�ɳɹ�
rem echo �����DisableIPSourceRouting=0x1
)

::������Ƭ��������
set  EnablePMTUDiscovery=False
for /f "skip=2 tokens=1-3" %%i in ('REG QUERY HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters') do (
	if "%%i"=="EnablePMTUDiscovery" if "%%k"=="0x0" set EnablePMTUDiscovery=True
)
if %EnablePMTUDiscovery%==False (
REG ADD HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters /f /v EnablePMTUDiscovery /t REG_DWORD /d 0
echo ������Ƭ���������ɹ�
rem echo �����EnablePMTUDiscovery=0x0
)

::Զ���������˿ڹ���
set  tcp_PortNumber=False
set  rdp-tcp_PortNumber=False
for /f "skip=2 tokens=1-3" %%i in ('REG QUERY HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Terminal" "Server\Wds\rdpwd\Tds\tcp') do (
	if "%%i"=="PortNumber" if "%%k"=="0xd3d" set tcp_PortNumber=True
)

for /f "skip=2 tokens=1-3" %%i in ('REG QUERY HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Terminal" "Server\WinStations\RDP-Tcp') do (
	if "%%i"=="PortNumber" if "%%k"=="0xd3d" set rdp-tcp_PortNumber=True
)
if %tcp_PortNumber%==True if %rdp-tcp_PortNumber%==True  (
echo ���޸�Զ������˿ڲ�ΪĬ�϶˿�3389
)

::�ն˷����¼����
set  DontDisplayLastUserName=False
for /f "skip=2 tokens=1-3" %%i in ('REG QUERY HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows" "NT\CurrentVersion\Winlogon') do (
	if "%%i"=="DontDisplayLastUserName" if "%%k"=="0x1" set DontDisplayLastUserName=True
)
if %DontDisplayLastUserName% == False (
REG ADD HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows" "NT\CurrentVersion\Winlogon /f /v DontDisplayLastUserName /t REG_DWORD /d 1
rem echo ���ֹ��ʾ�ϴε�¼�� DontDisplayLastUserName=0x1
)

::��ֹwindows�Զ���¼
set AutoAdminLogon=False
for /f  "skip=2 tokens=1,3" %%i in ('REG QUERY HKEY_LOCAL_MACHINE\Software\Microsoft\Windows" "NT\CurrentVersion\Winlogon\ /v AutoAdminLogon') do (
	if "%%j"=="0" set AutoAdminLogon=True
)
if %AutoAdminLogon%==False (
REG ADD HKEY_LOCAL_MACHINE\Software\Microsoft\Windows" "NT\CurrentVersion\Winlogon\ /f /v AutoAdminLogon /t REG_SZ /d 0
echo ��ֹwindows�Զ���¼�ɹ�
rem echo �����EnableDeadGWDetect=0
)

::����ϵͳ��������
::net start wuauserv

echo �������
pause







