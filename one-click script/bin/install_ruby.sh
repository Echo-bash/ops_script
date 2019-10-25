
ruby_install_set(){
	output_option "请选择安装方式" "编译安装 RVM安装" "install_method"
}

ruby_install(){
	if [[ ${install_method} = '1' ]];then
		install -y zlib-devel openssl-devel
		cd ${tar_dir}
		./configure --prefix=${home_dir}  --disable-install-rdoc
		make && make install
		add_sys_env "PATH=${home_dir}/bin:\$PATH"

	else
		gpg2 --keyserver hkp://pool.sks-keyservers.net --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3 7D2BAF1CF37B13E2069D6956105BD0E739499BDB
		curl -L get.rvm.io | bash -s stable
		source /etc/profile.d/rvm.sh
		rvm install ${version_number}
		rvm use ${version_number} --default
	fi
	gem sources --add http://gems.ruby-china.com/ --remove http://rubygems.org/
	ruby -v
	if [ $? = 0 ];then
		echo -e "${info} ruby环境搭建成功."
	else
		echo -e "${error} ruby环境搭建失败."
		exit 1
	fi
}

ruby_install_ctl(){
	install_version ruby
	ruby_install_set
	if [[ ${install_method} = '1' ]];then
		install_selcet
		install_dir_set
		download_unzip
	fi
	ruby_install
	clear_install
}
