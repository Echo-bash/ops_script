#!/bin/bash
. ./public.sh
. ./install_version.sh
activemq_install_set(){
	output_option '请选择安装模式' '单机模式 集群模式' 'deploy_mode'

	if [[ ${deploy_mode} = '2' ]];then
		output_option '请选择集群模式' 'Master-slave(高可用HA) Broker-clusters(负载均衡SLB) 混合模式' 'cluster_mode'
		if [[ ${cluster_mode} = '1' ]];then
			diy_echo '目前是基于共享文件的方式高可用方案' '' "$info"
			input_option '请输入共享文件夹目录' '/data/activemq' 'shared_dir'
			shared_dir=${input_value}
			input_option '请输入本机部署个数' '2' 'deploy_num'
		fi
		
		if [[ ${cluster_mode} = '2' ]];then
			input_option '请输入本机部署个数' '2' 'deploy_num'
		fi
		
		if [[ ${cluster_mode} = '3' ]];then
			input_option '请输入部署broker个数' '2' 'broker_num'
			input_option '请输入共享文件夹目录' '/data/activemq' 'shared_dir'
			shared_dir=${input_value}
			input_option '请输入本机部署个数' '2' 'deploy_num'
		fi
	fi
	input_option '请设置连接activemq的起始端口号' '61616' 'activemq_conn_port'
	input_option '请设置管理activemq的起始端口号' '8161' 'activemq_mana_port'
	input_option '请设置连接activemq的用户名' 'system' 'activemq_username'
	activemq_username=${input_value}
	input_option '请设置连接activemq的密码' 'manager' 'activemq_userpasswd'
	activemq_userpasswd=${input_value}
	echo -e "${info} press any key to continue"
	read
	
}

activemq_install(){
	
	if [[ ${deploy_mode} = '1' ]];then
		mv ${tar_dir} ${home_dir}
		activemq_config
		add_activemq_service
	fi
	if [[ ${deploy_mode} = '2' ]];then

		activemq_conn_port_default=${activemq_conn_port}
		activemq_mana_port_default=${activemq_mana_port}
		activemq_networkconn_port_default=${activemq_conn_port}

		for ((i=1;i<=${deploy_num};i++))
		do

			if [[ ${cluster_mode} = '1' || ${cluster_mode} = '2' ]];then
				\cp -rp ${tar_dir} ${install_dir}/activemq-node${i}
				home_dir=${install_dir}/activemq-node${i}
				activemq_config
				add_activemq_service
				activemq_conn_port=$((${activemq_conn_port}+1))
				activemq_mana_port=$((${activemq_mana_port}+1))
			fi
			
			if [[ ${cluster_mode} = '3' ]];then	

				#平均数
				average_value=$(((${deploy_num}/${broker_num})))
				#加权系数[0-(broker_num)]之间做为broker号
				weight_factor=$(((${i} % ${broker_num})))
				
				activemq_conn_port=${activemq_conn_port_default}
				activemq_mana_port=${activemq_mana_port_default}
				activemq_networkconn_port=${activemq_networkconn_port_default}
					
				activemq_conn_port=$((${activemq_conn_port}+${weight_factor}))
				activemq_mana_port=$((${activemq_mana_port}+${weight_factor}))
				#配置broker连接端口目前配置为环网连接
				if (( ${weight_factor} == $(((${broker_num} - 1))) ));then
					activemq_networkconn_port=${activemq_networkconn_port_default}
				else
					activemq_networkconn_port=$(((${activemq_networkconn_port_default}+${weight_factor}+1)))
				fi
					
				\cp -rp ${tar_dir} ${install_dir}/activemq-broker${weight_factor}-node${i}
				home_dir=${install_dir}/activemq-broker${weight_factor}-node${i}
				activemq_config
				add_activemq_service
			fi
		done
	fi

}

activemq_config(){

	cat > /tmp/activemq.xml.tmp << 'EOF'
        <plugins> 
           <simpleAuthenticationPlugin> 
                 <users> 
                      <authenticationUser username="${activemq.username}" password="${activemq.password}" groups="users,admins"/> 
                 </users> 
           </simpleAuthenticationPlugin> 
        </plugins>
EOF
	
	cat > /tmp/activemq.xml.networkConnector.tmp << EOF
				<networkConnectors>
						<networkConnector uri="static:(tcp://0.0.0.0:61616)" duplex="true" userName="${activemq_username}" password="${activemq_userpasswd}"/>
				</networkConnectors>	
EOF


	if [[ ${deploy_mode} = '1' ]];then
		#插入文本内容
		sed -i '/<\/persistenceAdapter>/r /tmp/activemq.xml.tmp' ${home_dir}/conf/activemq.xml
		#注释无用的消息协议只开启tcp
		sed -i 's#<transportConnector name#<!-- <transportConnector name#' ${home_dir}/conf/activemq.xml
		sed -i 's#maxFrameSize=104857600"/>#maxFrameSize=104857600"/> -->#' ${home_dir}/conf/activemq.xml
		sed -i 's#<!-- <  name="openwire".*maxFrameSize=104857600"/> -->#<transportConnector name="openwire" uri="tcp://0.0.0.0:61616?maximumConnections=1000\&amp;wireFormat.maxFrameSize=104857600"/>#' ${home_dir}/conf/activemq.xml
		#配置链接用户密码
		sed -i 's#activemq.username=system#activemq.username='${activemq_username}'#' ${home_dir}/conf/credentials.properties
		sed -i 's#activemq.password=manager#activemq.password='${activemq_userpasswd}'#' ${home_dir}/conf/credentials.properties
	elif [[ ${deploy_mode} = '2' ]];then
		
			#插入文本内容
			sed -i '/<\/persistenceAdapter>/r /tmp/activemq.xml.tmp' ${home_dir}/conf/activemq.xml
			#注释无用的消息协议只开启tcp
			sed -i 's#<transportConnector name#<!-- <transportConnector name#' ${home_dir}/conf/activemq.xml
			sed -i 's#maxFrameSize=104857600"/>#maxFrameSize=104857600"/> -->#' ${home_dir}/conf/activemq.xml
			sed -i 's#<!-- <transportConnector name="openwire".*maxFrameSize=104857600"/> -->#<transportConnector name="openwire" uri="tcp://0.0.0.0:61616?maximumConnections=1000\&amp;wireFormat.maxFrameSize=104857600"/>#' ${home_dir}/conf/activemq.xml
			#配置链接用户密码
			sed -i 's#activemq.username=system#activemq.username='${activemq_username}'#' ${home_dir}/conf/credentials.properties
			sed -i 's#activemq.password=manager#activemq.password='${activemq_userpasswd}'#' ${home_dir}/conf/credentials.properties

		if [[ ${cluster_mode} = '1' ]];then
			sed -i 's#<kahaDB directory="${activemq.data}/kahadb"/>#<kahaDB directory="'${shared_dir}'"/>#' ${home_dir}/conf/activemq.xml

		elif [[ ${cluster_mode} = '2' ]];then
			sed -i 's#brokerName="localhost"#brokerName="broker'${i}'"#' ${home_dir}/conf/activemq.xml
			sed -i '/<\/plugins>/r /tmp/activemq.xml.networkConnector.tmp' ${home_dir}/conf/activemq.xml
			sed -i 's#<transportConnector name="openwire" uri="tcp://0.0.0.0:61616#<transportConnector name="openwire" uri="tcp://0.0.0.0:'${activemq_conn_port}'#' ${home_dir}/conf/activemq.xml
			sed -i 's#<property name="port" value="8161"/>#<property name="port" value="'${activemq_mana_port}'"/>#' ${home_dir}/conf/jetty.xml
		elif [[ ${cluster_mode} = '3' ]];then
			sed -i 's#brokerName="localhost"#brokerName="broker'${weight_factor}'"#' ${home_dir}/conf/activemq.xml
			sed -i 's#<kahaDB directory="${activemq.data}/kahadb"/>#<kahaDB directory="'${shared_dir}'/broker'${weight_factor}'"/>#' ${home_dir}/conf/activemq.xml
			sed -i '/<\/plugins>/r /tmp/activemq.xml.networkConnector.tmp' ${home_dir}/conf/activemq.xml
			sed -i 's#<networkConnector uri="static:(tcp://0.0.0.0:61616)#<networkConnector uri="static:(tcp://0.0.0.0:'${activemq_networkconn_port}')#' ${home_dir}/conf/activemq.xml
			sed -i 's#<transportConnector name="openwire" uri="tcp://0.0.0.0:61616#<transportConnector name="openwire" uri="tcp://0.0.0.0:'${activemq_conn_port}'#' ${home_dir}/conf/activemq.xml
			sed -i 's#<property name="port" value="8161"/>#<property name="port" value="'${activemq_mana_port}'"/>#' ${home_dir}/conf/jetty.xml
		fi
	fi
}

add_activemq_service(){

	Type="forking"
	Environment="JAVA_HOME=$(echo $JAVA_HOME)"
	ExecStart="${home_dir}/bin/activemq start"
	ExecStop="${home_dir}/bin/activemq stop"
	conf_system_service
	if [[ ${deploy_mode} = '1' ]];then
		add_system_service activemq ${home_dir}/init
	fi
	if [[ ${deploy_mode} = '2' ]];then
		if [[ ${cluster_mode} = '1' ]];then		
			add_system_service activemq-node${i} ${home_dir}/init
		fi
		if [[ ${cluster_mode} = '2' ]];then	
			add_system_service activemq-broker${i}-node${i} ${home_dir}/init
		fi
		if [[ ${cluster_mode} = '3' ]];then
			add_system_service activemq-broker${weight_factor}-node${i} ${home_dir}/init
		fi
	fi

}

install_version activemq
install_selcet
activemq_install_set
install_dir_set
download_unzip
activemq_install
clear_install