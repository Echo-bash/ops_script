#install nfs script
nfs_install_ctl(){
	input_option "请输入要共享的目录:" "/data/nfs" "nfs_dir"
	nfs_dir=${input_value}
	yum install -y nfs-utils
	cat >>/etc/exports<<-EOF
	${nfs_dir} *(rw,sync)
	EOF
	[[ -d ${nfs_dir} ]] && mkdir -p ${nfs_dir}
	start_arg='y'
	service_control nfs
}