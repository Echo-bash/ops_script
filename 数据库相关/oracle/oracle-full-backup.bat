@echo off
echo ================================================   
echo  Windows������Oracle���ݿ���Զ����ݽű�
echo  1. ʹ�õ�ǰ�������������ļ���
echo  2. �Զ�ɾ��7��ǰ�ı��ݡ�
echo ================================================  
::�ԡ�YYYYMMDD����ʽȡ����ǰʱ�䡣
set BACKUPDATE=%date:~0,4%%date:~5,2%%date:~8,2%
::�����û����������Ҫ���ݵ����ݿ⡣
set USER=system
set PASSWORD=123456
set DATABASE=ORCL
::��������Ŀ¼
if not exist "D:\backup\data"       mkdir D:\backup\data
if not exist "D:\backup\log"        mkdir D:\backup\log
set DATADIR=D:\backup\data
set LOGDIR=D:\backup\log
exp %USER%/%PASSWORD%@192.168.30.40:1521/%DATABASE% full=y file=%DATADIR%\data_%BACKUPDATE%.dmp log=%LOGDIR%\log_%BACKUPDATE%.log
::ɾ��7��ǰ�ı��ݡ�  
forfiles /p "%DATADIR%" /s /m *.* /d -7 /c "cmd /c del @path"
forfiles /p "%LOGDIR%" /s /m *.* /d -7 /c "cmd /c del @path"