@echo off
echo ================================================   
echo  Windows������Mysql���ݿ���Զ��ָ��ű�
echo  1. ʹ�õ�ǰ�������������ļ���
echo  2. �Զ�ɾ��7��ǰ�ı��ݡ�
echo ================================================  
::�ԡ�YYYYMMDD����ʽȡ����ǰʱ�䡣
set BACKUPDATE=%date:~0,4%%date:~5,2%%date:~8,2%
::�����û����������Ҫ�ָ������ݿ⡣
set USER=root
set PASSWORD=123456
set DATABASE=mysql
set MYSQLIP=192.168.30.47
::�����ָ�Ŀ¼
if not exist "D:\backup\data"       mkdir D:\backup\data
set DATADIR=D:\backup\data
mysql -h%MYSQLIP% -u%USER% -p%PASSWORD% %DATABASE% < %DATADIR%\data-%BACKUPDATE%.sql

pause