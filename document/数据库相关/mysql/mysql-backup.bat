@echo off
echo ================================================   
echo  windows������mysql���ݿ���Զ����ݽű�
echo  1. ʹ�õ�ǰ�������������ļ���
echo  2. �Զ�ɾ��30��ǰ�ı��ݡ�
echo ================================================  
::�ԡ�yyyymmdd����ʽȡ����ǰʱ�䡣
set backupdate=%date:~0,4%%date:~5,2%%date:~8,2%
::�����û����������Ҫ���ݵ����ݿ⡣
set user=root
set password=123456
set mysqlip=192.168.10.21
set mysqlhome="d:\mysql\mysql server 5.6"
set datadir=d:\backup\data
set databases=db_librarysys mysql
set logfile=d:\backup\data\log.txt
echo ����ʱ��:%backupdate%>>%logfile%
::��������Ŀ¼
if not exist "%datadir%" mkdir "%datadir%"
setlocal enabledelayedexpansion
for %%d in (%databases%) do (
   set dbname=%%d

    %mysqlhome%\bin\mysqldump -h%mysqlip% -u%user% -p%password% !dbname! --log-error=%LogFile%>%datadir%\data-!dbname!-%backupdate%.sql
    if !errorlevel! == 0 (
      echo ���ݿ�!dbname!���ݳɹ�>>%logfile%
      forfiles /p "%datadir%" /s /m *.* /d -1 /c "cmd /c del @path"
    ) else (
      echo ���ݿ�!dbname!����ʧ��>>%logfile%
    )
)
echo �������>>%logfile%