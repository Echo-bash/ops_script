#!/bin/bash
# 该脚本为监听文件修改时触发sync同步
# 每个模式名称对应关联一个需要同步的目录，要求模式名唯一
declare -A rsync_module_name=([clickhouse]='/data/clickhouse' [k8score]='/data/k8score' [k8smonitor]='/data/k8smonitor')
# 监听排除目录
declare -A exclude_file_rule=([clickhouse]='tmp_insert|tmp_merge|delete_tmp' [k8score]='' [k8smonitor]='')
# rsync脚本路径
sersync_dir=/usr/local/sersync/sersync.sh

inotify_fun(){
	i=1
	cd $sync_dir
	if [[ -n ${exclude_file} ]];then
		inotifywait --exclude "${exclude_file}" -mrq --format  "%Xe %w%f" -e create,delete,attrib,close_write,move ./ | while read event file
		do
			echo "${sync_dir} ${module_name} ${event} ${file}" >> /tmp/inotify-file.log
		done
	else
		inotifywait -mrq --format  "%Xe %w%f" -e create,delete,attrib,close_write,move ./ | while read event file
		do
			echo "${sync_dir} ${module_name} ${event} ${file}" >> /tmp/inotify-file.log
		done
	fi
}

rsync_fun(){
	while true
	do 
		sleep 20
		\mv /tmp/inotify-file.log /tmp/inotify-tmp.log
		sort -u /tmp/inotify-tmp.log | while read sync_dir module_name event file
		do
			$sersync_dir $sync_dir $module_name $event $file &
		done
	done
}

run_ctl(){
	for i in ${!rsync_module_name[@]}
	do
		#rsyncd模块名
		module_name="${i}"
		#同步目录
		sync_dir="${rsync_module_name[$i]}"
		#监听排除规则
		exclude_file="${exclude_file_rule[$i]}"
		inotify_fun &
	done
	rsync_fun &
}


run_ctl
