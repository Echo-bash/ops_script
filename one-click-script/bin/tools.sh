#!/bin/bash

auto_ssh_keygen(){
	expect_dir=`which expect 2>/dev/null`
	[ -z ${expect_dir} ] && yum install expect -y
	input_option "请输入ssh互信主机的信息,格式ip:port:passwd(多个空格隔开)" "127.0.0.1:22:root:123456" "ssh_ip"
	ssh_ip=(${input_value[@]})
	[ ! -f /root/.ssh/id_rsa ] && ssh-keygen -t rsa -N '' -f ~/.ssh/id_rsa -q
	for ip in ${ssh_ip[@]}
	do
		addr=`echo $ip | awk -F : '{print $1}'`
		port=`echo $ip | awk -F : '{print $2}'`
		user=`echo $ip | awk -F : '{print $3}'`
		passwd=`echo $ip | awk -F : '{print $4}'`
		expect <<-EOF
		spawn ssh-copy-id -i /root/.ssh/id_rsa.pub ${user}@${addr} -p ${port}
		expect {
			"yes/no" {send "yes\r";exp_continue}
			"password:" {send "$passwd\r";exp_continue}
        }
		EOF
	done
}

add_sysuser_sudo(){
  #add visudo
  echo -e "${info} Add user to sudoers file"
  [ ! -f /etc/sudoers.back ] && \cp /etc/sudoers /etc/sudoers.back
  SUDO=`grep -w "$name" /etc/sudoers |wc -l`
  if [ $SUDO -eq 0 ];then
      sed -i '/^root/i '${name}'  ALL=(ALL)       NOPASSWD: ALL' /etc/sudoers
      sleep 1
  fi
  [ ! -z `grep -ow "$name" /etc/sudoers` ] && action "创建用户$name并将其加入visudo"  /bin/true
}

add_sysuser_sftp(){
	#set sftp homedir
	echo -e "${info} Please enter sftp home directory"
	read -p "(default:/data/${name}/sftp)" sftp_dir
	if [[ ${sftp_dir} = '' ]];then
		sftp_dir="/data/${name}/sftp"
	fi
	if [[ ! -d ${sftp_dir} ]];then
		mkdir -p ${sftp_dir}
	fi
	#父目录
	dname=$(dirname ${sftp_dir})
	groupadd sftp_users>/dev/null 2>&1
	usermod -G sftp_users -d ${dname} -s /sbin/nologin ${name}>/dev/null 2>&1
	chown -R ${name}.sftp_users ${sftp_dir}
	sed -i 's[^Subsystem.*sftp.*/usr/libexec/openssh/sftp-server[#Subsystem	sftp	/usr/libexec/openssh/sftp-server[' /etc/ssh/sshd_config
	if [[ -z `grep -E '^ForceCommand    internal-sftp' /etc/ssh/sshd_config` ]];then
		cat >>/etc/ssh/sshd_config<<EOF
Subsystem       sftp    internal-sftp
Match Group sftp_users
ChrootDirectory %h
ForceCommand    internal-sftp
EOF
	fi
}

update_kernel(){
	diy_echo 'Updating kernel is risky. Please backup information.' "${red}"
	echo -e "${info} The current kernel version is ${kel}"
	echo -e "${info} press any key to continue"
	read
	output_option '选择升级kernel类型' '长期维护版 最新版' 'kernel_type'
	if [ ! -f /etc/yum.repos.d/elrepo.repo ]; then
		rpm --import https://www.elrepo.org/RPM-GPG-KEY-elrepo.org
		if (( ${os_release} < '7' ));then
			rpm -Uvh http://www.elrepo.org/elrepo-release-6-8.el6.elrepo.noarch.rpm
		elif (( ${os_release} >= '7' ));then
			rpm -Uvh http://www.elrepo.org/elrepo-release-7.0-3.el7.elrepo.noarch.rpm
		fi
	fi
		
	if [ ! -f /etc/yum.repos.d/elrepo.repo ]; then
		echo -e "${error} Install elrepo failed, please check it."
		exit 1
	fi
	if [[ ${kernel_type} = '1' ]];then
		yum --enablerepo=elrepo-kernel install  -y kernel-lt kernel-lt-devel
	else
		yum --enablerepo=elrepo-kernel install  -y kernel-ml kernel-ml-devel
	fi
	if [[ $? != '0' ]];then
		echo -e "${error} Failed to install kernel, please check it"
		exit 1
	fi
	if (( ${os_release} < '7' ));then
		if [ ! -f "/boot/grub/grub.conf" ]; then
			echo -e "${error} /boot/grub/grub.conf not found, please check it."
			exit 1
		fi
		sed -i 's/^default=.*/default=0/g' /boot/grub/grub.conf
	elif (( ${os_release} >= '7' ));then
		if [ ! -f "/boot/grub2/grub.cfg" ]; then
			echo -e "${error} /boot/grub2/grub.cfg not found, please check it."
			exit 1
		fi
		grub2-set-default 0
	fi
	echo -e "${info} The system needs to reboot."
    read -p "Do you want to restart system? [y/n]" is_reboot
    if [[ ${is_reboot} = "y" || ${is_reboot} = "Y" ]]; then
        reboot
    else
        echo -e "${info} Reboot has been canceled..."
        exit 0
    fi
}

clear_install(){
	if [[ -n ${install_dir} ]];then
		rm -rf ${install_dir}/${file_name}
		rm -rf ${tar_dir}
	fi
}
