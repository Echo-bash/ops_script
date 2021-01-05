#!/bin/bash
source /usr/local/greenplum-db/greenplum_path.sh
###日志目录
logfile=/home/gpadmin/itp_tool/greenplum_row_to_col.log
###开始时间与结束时间差必须大于定时任务执行间隔
###数据时间间隔可选【1 days】【1 hour】
time_interval='1 hour'
###数据时间间隔可选【1 days】【1 hour】
###以天为时间间隔的开始时间
#start_time=`date -d "-${time_interval}" +"%Y-%m-%d"`
###以小时为时间间隔的开始时间
start_time=`date -d "-${time_interval}" +"%Y-%m-%d %H:%M"`
###以天为时间间隔的结束时间
#end_time=`date +"%Y-%m-%d"`
###以小时为时间间隔的结束时间
end_time=`date +"%Y-%m-%d %H:%M"`


#数据库名
database_name='tyacc_tytest'
#查询条件
index_name=('createdAt' 'updatedAt')
#源模式
source_schema='AFC_ITP_BUSINESS'
#目标模式
target_schema='AFC_ITP_BIZ_COL'
#业务行式表
business_table=('app_pay_bills' 'devices' 'inout_records' 'mobile_pay_bills' 'mobile_pay_orders' 'mobile_pay_refundorders' 'orders' 'single_ticket_trip_records' 'single_tickets' 'stations' 'ticket_matrices' 'user_accounts' 'user_details' 'user_pay_accounts' 'user_phone_login')
#数仓列式表
dat_warehouse_table=('app_pay_bills' 'devices' 'inout_records' 'mobile_pay_bills' 'mobile_pay_orders' 'mobile_pay_refundorders' 'orders' 'single_ticket_trip_records' 'single_tickets' 'stations' 'ticket_matrices' 'user_accounts' 'user_details' 'user_pay_accounts' 'user_phone_login')


delete_old_data(){
	psql -d ${database_name} << EOF
\timing
DELETE 
FROM
	"${target_schema}"."${dat_warehouse_table[$i]}" 
WHERE
	"${target_schema}"."${dat_warehouse_table[$i]}"."${index}" > '${start_time}' 
	AND "${target_schema}"."${dat_warehouse_table[$i]}"."${index}" <= '${end_time}';
EOF

}

delete_updata_old_data(){
#对于存在有超过开始结束时间差的数据单独处理
#将有更新的数据通过行式表id查询出来匹配到列式表数据删除
	psql -d ${database_name} << EOF
\timing
DELETE
FROM
	"${target_schema}"."${dat_warehouse_table[$i]}" 
WHERE
	"id" IN (SELECT "id" FROM "${source_schema}"."${business_table[$i]}" WHERE "createdAt" < '${start_time}' AND "updatedAt" >= '${end_time}');
EOF
}

inset_new_data(){
	psql -d ${database_name} << EOF
\timing
INSERT INTO "${target_schema}"."${dat_warehouse_table[$i]}" 
SELECT
	"${source_schema}"."${business_table[$i]}".* 
FROM
	"${source_schema}"."${business_table[$i]}" 
WHERE
	"${source_schema}"."${business_table[$i]}"."${index}" > '${start_time}' 
	AND "${source_schema}"."${business_table[$i]}"."${index}" <= '${end_time}';
EOF
}

inset_updata_new_data(){
#对于存在有超过开始结束时间差的数据单独处理
#将有更新的数据通过行式表id查询出来插入到列式表
	psql -d ${database_name} << EOF
\timing
INSERT INTO "${target_schema}"."${dat_warehouse_table[$i]}" 
SELECT
	"${source_schema}"."${business_table[$i]}".* 
FROM
	"${source_schema}"."${business_table[$i]}" 
WHERE
    "createdAt" < '${start_time}' AND "updatedAt" >= '${end_time}';
EOF
}

start_run_time=`date`
echo "${start_run_time}" >>$logfile
i=0
for now_table in ${business_table[@]}
do
	if [[ ${now_table} = 'app_pay_bills' ]];then
		echo "deleting ${now_table} data" >>$logfile
		index='updatedAt'
		delete_old_data >>$logfile
		delete_updata_old_data >>$logfile
		echo "updating ${now_table} data" >>$logfile
		inset_new_data >>$logfile
		inset_updata_new_data >>$logfile
		((i++))
	else
		index='createdAt'
		echo "deleting ${now_table} data" >>$logfile
		delete_old_data >>$logfile
		delete_updata_old_data >>$logfile
		echo "updating ${now_table} data" >>$logfile
		inset_new_data >>$logfile
		inset_updata_new_data >>$logfile
		((i++))
	fi
done
end_run_time=`date`
echo "${end_run_time}" >>$logfile
