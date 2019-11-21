#!/bin/bash
###########################################################
#System Required: Centos 6+
#Description: Install the java tomcat mysql and tools
#Version: 2.0
#                                                        
#                            by---wang2017.7
###########################################################
workdir=$(cd $(dirname $0); pwd)
. ${workdir}/bin/public.sh
. ${workdir}/bin/version_down_unzip.sh
. ${workdir}/bin/system_set.sh
. ${workdir}/bin/tools.sh
. ${workdir}/bin/basic_environment.sh
. ${workdir}/bin/web_services.sh
. ${workdir}/bin/database_services.sh
. ${workdir}/bin/middleware_services.sh
. ${workdir}/bin/storage_service.sh
. ${workdir}/bin/operation_platform.sh

mysql_tool(){
output_option 'MySQL常用脚本' '添加MySQL备份脚本  找回MySQLroot密码 ' 'num'

case "$num" in
	1)multi_function_backup_script_set
	;;
	2)reset_mysql_passwd
	;;
esac
}

basic_environment(){

output_option '请选择要安装的环境' 'JDK PHP Ruby Nodejs' 'num'
case "$num" in
	1)java_install_ctl
	;;
	2)php_install_ctl
	;;
	3)ruby_install_ctl
	;;
	4)node_install_ctl
	;;
esac
}

web_services(){

output_option '请选择要安装的软件' 'Nginx Tomcat' 'num'
case "$num" in
	1)nginx_install_ctl
	;;
	2)tomcat_install_ctl
	;;
esac
}

database_services(){

output_option '请选择要安装的软件' 'MySQL mongodb Redis Memcached' 'num'
case "$num" in
	1)mysql_install_ctl
	;;
	2)mongodb_inistall_ctl
	;;
	3)redis_install_ctl
	;;
	4)memcached_inistall_ctl
	;;
esac
}

middleware_services(){

output_option '请选择要安装的软件' 'ActiveMQ RocketMQ Zookeeper Kafka' 'num'
case "$num" in
	1)activemq_install_ctl
	;;
	2)rocketmq_install_ctl
	;;
	3)zookeeper_install_ctl
	;;
	4)kafka_install_ctl
	;;
esac
}

storage_service(){

output_option '请选择要安装的软件' 'FTP SFTP 对象存储服务(OSS/minio) FastDFS NFS' 'num'
case "$num" in
	1)ftp_install_ctl
	;;
	2)add_sysuser && add_sysuser_sftp
	;;
	3)minio_install_ctl
	;;
	4)fastdfs_install_ctl
	;;
	5)nfs_install_ctl
	;;
esac
}

operation_platform(){
output_option '请选择要安装的平台' 'K8S系统 ELK日志平台 Zabbix监控 Rancher平台(k8s集群管理)' 'platform'
case "$platform" in
	1)k8s_install_ctl
	;;
	2)elk_install_ctl
	;;
	3)zabbix_install_ctl
	;;
esac

}

tools(){
output_option '请选择进行的操作' '优化系统配置 查看系统详情 升级内核版本 创建用户并将其加入visudo 安装WireGuard-VPN 多功能备份脚本 主机ssh互信' 'tool'
case "$tool" in
	1)system_optimize_set
	;;
	2)sys_info_detail
	;;
	3)update_kernel
	;;
	4)add_sysuser && add_sysuser_sudo
	;;
	5)wireguard_order
	;;
	6)multi_function_backup_script_set
	;;
	7)auto_ssh_keygen
	;;
esac
}

main(){

output_option '请选择需要安装的服务' '基础环境 WEB服务 数据库服务 中间件服务 存储服务 运维平台 其他工具' 'mian'

case "$mian" in
	1)basic_environment
	;;
	2)web_services
	;;
	3)database_services
	;;
	4)middleware_services
	;;
	5)storage_service
	;;
	6)operation_platform
	;;
	7)tools
	;;

esac
}


clear
[[ $EUID -ne 0 ]] && echo -e "${error} Need to use root account to run this script!" && exit 1
echo -e "+ + + + + + + + + + + + + + + + + + + + + + + + + +"
echo -e "+ System Required: Centos 6+                      +"
echo -e "+ Description: Multi-function one-click script    +"
echo -e	"+                                                 +"
echo -e "+                                   Version: 2.1  +"
echo -e "+                                 by---wang2017.7 +"
echo -e "+ + + + + + + + + + + + + + + + + + + + + + + + + +"

sys_info
main

