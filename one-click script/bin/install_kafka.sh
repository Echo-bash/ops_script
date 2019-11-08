#install kafka script
kafka_install_set(){
	output_option '请选择安装模式' '单机模式 集群模式' 'deploy_mode'
	if [[ ${deploy_mode} = '1' ]];then
		input_option '请设置kafka的端口号' '9092' 'kafka_port'
	elif [[ ${deploy_mode} = '2' ]];then
		input_option '请输入本机部署个数' '1' 'deploy_num_local'
		input_option '请设置kafka的起始端口号' '9092' 'kafka_port'
		diy_echo "集群内broker.id不能重复" "${yellow}" "${info}"
		input_option '请设置kafka的broker id' '0' 'kafka_id'
	fi
	input_option '请设置kafka数据目录' '/data/kafka' 'kafka_data_dir'
	diy_echo "此处建议使用单独zookeeper服务" "${yellow}" "${info}"
	input_option '请设置kafka连接的zookeeper地址池' '192.168.1.2:2181 192.168.1.3:2181 192.168.1.4:2181' 'zookeeper_ip'
	zookeeper_ip=(${input_value[@]})
}

kafka_install(){

	if [[ ${deploy_mode} = '1' ]];then
		mv ${tar_dir} ${home_dir}
		kafka_config
		add_kafka_service
	fi
	
	if [[ ${deploy_mode} = '2' ]];then
		
		for ((i=1;i<=${deploy_num_local};i++))
		do
			cp -rp ${tar_dir} ${install_dir}/kafka-node${i}
			home_dir=${install_dir}/kafka-node${i}
			kafka_config
			add_kafka_service
			kafka_port=$((${kafka_port}+1))
		done
	fi
}

kafka_config(){
	mkdir -p ${home_dir}/{logs,data}
	conf_dir=${home_dir}/config
	[[ -n ${kafka_id} ]] && sed -i "s/broker.id=0/broker.id=${kafka_id}/" ${conf_dir}/server.properties
	sed -i "/broker.id=.*/aport=${kafka_port}" ${conf_dir}/server.properties
	sed -i "s/log.dirs=.*/log.dirs=${kafka_data_dir}/${kafka_port}" ${conf_dir}/server.properties
	zookeeper_ip="${zookeeper_ip[@]}"
	zookeeper_connect=$(echo ${zookeeper_ip} | sed 's/ /,/g')
	sed -i "s/zookeeper.connect=localhost:2181/zookeeper.connect=${zookeeper_connect}/" ${conf_dir}/server.properties
}

add_kafka_service(){
	Type=simple
	ExecStart="${home_dir}/bin/kafka-server-start.sh ${home_dir}/config/server.properties"
	ExecStop="${home_dir}/bin/kafka-server-stop.sh"
	Environment="JAVA_HOME=$(echo $JAVA_HOME) KAFKA_HOME=${home_dir}"
	conf_system_service 

	if [[ ${deploy_mode} = '1' ]];then
		add_system_service kafka ${home_dir}/init
	else
		add_system_service kafka-node${i} ${home_dir}/init
	fi
}

kafka_install_ctl(){
	install_version kafka
	install_selcet
	kafka_install_set
	install_dir_set
	download_unzip
	kafka_install
	clear_install
}
