### Greenplum常用语句

查看用户信息

```sql
select * from pg_user;
```

新增用户

```sql
create user tableau with nosuperuser nocreatedb password 'tableau';
```

更改密码

```sql
alter user gpadmin with password 'gpadmin';
```


获取锁信息

```sql
select * from gp_toolkit.gp_locks_on_relation;
```

获取当前正在运行的SQL

```sql
select * from pg_stat_activity;
```

获取当前的连接数

```sql
select count(*) from pg_stat_activity where state = 'active';
```

查看表的存储结构

```sql
select distinct relstorage from pg_class;
```

​	a  -- 行存储AO表    
​	h  -- heap堆表、索引    
​	x  -- 外部表(external table)    
​	v  -- 视图    
​	c  -- 列存储AO表
​	
查询当前数据库有哪些AO表

```sql
select t2.nspname, t1.relname from pg_class t1, pg_namespace t2 where t1.relnamespace=t2.oid and relstorage in ('c', 'a');
```

查询当前数据库有哪些HEAP表

```sql
select t2.nspname, t1.relname from pg_class t1, pg_namespace t2 where t1.relnamespace=t2.oid and relstorage in ('h');
```

查询表大小

```sql
select pg_size_pretty(pg_relation_size('open.dwd_wallet_info'));
```


查整个库的大小

```sql
select pg_size_pretty(pg_database_size('gp_pay'));
```

查看表膨胀信息

```sql
SELECT
  schemaname || '.' || relname as table_name,
  pg_size_pretty(
    pg_relation_size('"' || schemaname || '"' || '.' || relname)
  ) as table_size,
  n_dead_tup,
  n_live_tup,
  round(n_dead_tup * 100 / (n_live_tup + n_dead_tup), 2) AS dead_tup_ratio
FROM
  pg_stat_all_tables
WHERE
  n_dead_tup >= 10000
ORDER BY
  dead_tup_ratio DESC
LIMIT
  20;
```


长事务查询

```sql
SELECT
  pid,
  client_addr,
  usename,
  datname,
  waiting,
  clock_timestamp() - xact_start AS xact_age,
  clock_timestamp() - query_start AS query_age,
  state,
  query
FROM
  pg_stat_activity
WHERE
  (
    now() - xact_start > interval '10 sec'
    OR now() - query_start > interval '10 sec'
  )
  AND query !~ '^COPY'
  AND state LIKE '%transaction%'
ORDER BY
  coalesce(xact_start, query_start);
```


长连接查询

```sql
SELECT
  pid,
  client_addr,
  usename,
  datname,
  waiting,
  clock_timestamp() - xact_start AS xact_age,
  clock_timestamp() - query_start AS query_age,
  state,
  query
FROM
  pg_stat_activity
WHERE
  (
    now() - xact_start > interval '1 day'
    OR now() - query_start > interval '1 day'
  )
  AND query !~ '^COPY'
  AND NOT STATE LIKE '%transaction%'
ORDER BY
  coalesce(xact_start, query_start);
```

结束sql

```sql
select pg_terminate_backend(pid);
```

批量结束

```sql
SELECT
  pg_terminate_backend(pid)
FROM
  (
    SELECT
      pid
    FROM
      pg_stat_activity
    WHERE
      (
        now() - xact_start > interval '3600 sec'
        OR now() - query_start > interval '3600 sec'
      )
      AND query !~ '^COPY'
      AND state LIKE '%transaction%'
    ORDER BY
      coalesce(xact_start, query_start)
```

查看表状态

```sql
select * from pg_stat_all_tables;
```

查看节点

```sql
select * from gp_segment_configuration;
```



### Greenplum维护

GreenPlum备份与恢复

* 备份

  ```shell
  全量备份
  gpbackup --dbname test1 --backup-dir /tmp --leaf-partition-data
  增量备份
  gpbackup --dbname test1 --backup-dir /tmp --leaf-partition-data --incremental
  ```
  
* 用法
  	gpbackup [标志]

  ```shell
  标志：
    --backup-dir字符串将所有备份文件写入的目录的绝对路径
    --compression-level int数据备份期间要使用的压缩级别。有效值在1到9之间。（默认值为1）
    --data-only仅备份数据，不备份元数据
    --dbname字符串要备份的数据库
    --debug打印详细信息并调试日志消息
    --exclude-schema stringArray备份除指定架构中的对象以外的所有元数据。 --exclude-schema可以多次指定。
    --exclude-schema-file字符串包含要从备份中排除的模式列表的文件
    --exclude-table stringArray备份除指定表以外的所有元数据。 --exclude-table可以多次指定。
    --exclude-table-file字符串包含要从备份中排除的标准表列表的文件
    --from-timestamp字符串用于基于当前增量备份的时间戳
    --help gpbackup的帮助
    --include-schema stringArray仅备份指定的架构。 --include-schema可以多次指定。
    --include-schema-file string包含要包含在备份中的模式列表的文件
    --include-table stringArray仅备份指定的表。 --include-table可以多次指定。
    --include-table-file字符串包含要包含在备份中的标准表列表的文件
    --incremental仅备份自上次备份以来已修改的AO表的数据
    --jobs int备份数据时使用的并行连接数（默认为1）
    --leaf-partition-data对于分区表，为每个叶分区创建一个数据文件，而不是为整个表创建一个数据文件
    --metadata-only仅备份元数据，不备份数据
    --no-compression禁用数据文件压缩
    --plugin-config字符串用于插件的配置文件
    --quiet禁止非警告，非错误的日志消息
    --single-data-file将所有数据备份到一个文件，而不是每个表一个
    --verbose打印详细日志消息
    --version打印版本号并退出
    --with-stats备份查询计划统计信息
    --without-globals禁用全局元数据的备份
  ```
  
* 恢复

  ```shell
  gprestore --backup-dir /tmp --timestamp 20200707144340 --redirect-db test2 --data-only --incremental
  ```

* 用法：
  gprestore [标志]

  ```shell
  标志：
    --backup-dir字符串要还原的备份文件所在的目录的绝对路径
    --create-db在元数据还原之前创建数据库
    --data-only仅还原数据，不还原元数据
    --debug打印详细信息并调试日志消息
    --exclude-schema stringArray还原除指定架构中的对象以外的所有元数据。 --exclude-schema可以多次指定。
    --exclude-schema-file字符串包含将无法还原的模式列表的文件
    --exclude-table stringArray恢复除指定关系之外的所有元数据。 --exclude-table可以多次指定。
    --exclude-table-file字符串包含将无法恢复的完全限定关系列表的文件
    --help gprestore的帮助
    --include-schema stringArray仅还原指定的架构。 --include-schema可以多次指定。
    --include-schema-file string包含要还原的模式列表的文件
    --include-table stringArray仅还原指定的关系。 --include-table可以多次指定。
    --include-table-file string包含将恢复的完全限定关系列表的文件
    --incremental BETA功能：仅还原所有堆表和自上次备份以来已修改的AO表的数据
    --jobs int恢复表数据和后数据时要使用的并行连接数（默认为1）
    --metadata-only仅还原元数据，不还原数据
    --on-error-continue记录错误并继续还原，而不是在出现第一个错误时退出
    --plugin-config字符串用于插件的配置文件
    --quiet禁止非警告，非错误的日志消息
    --redirect-db字符串还原到指定的数据库，而不是备份的数据库
    --redirect-schema字符串恢复到指定的架构，而不是已备份的架构
    --timestamp字符串要恢复的时间戳，格式为YYYYMMDDHHMMSS
    --truncate-table删除要恢复的表的数据
    --verbose打印详细日志消息
    --version打印版本号并退出
    --with-globals恢复全局元数据
    --with-stats恢复查询计划统计信息
  ```
  
  GreenPlum其他命令
  
  ```shell
  gpstate
  命令     参数   作用 
  gpstate -b => 显示简要状态
  gpstate -c => 显示主镜像映射
  gpstart -d => 指定数据目录（默认值：$MASTER_DATA_DIRECTORY）
  gpstate -e => 显示具有镜像状态问题的片段
  gpstate -f => 显示备用主机详细信息
  gpstate -i => 显示GRIPLUM数据库版本
  gpstate -m => 显示镜像实例同步状态
  gpstate -p => 显示使用端口
  gpstate -Q => 快速检查主机状态
  gpstate -s => 显示集群详细信息
  gpstate -v => 显示详细信息
  ```
  
  ```shell
  gpconfig
  命令    参数                              作用
  gpconfig -c => --change param_name  通过在postgresql.conf 文件的底部添加新的设置来改变配置参数的设置。
  gpconfig -v => --value value 用于由-c选项指定的配置参数的值。默认情况下，此值将应用于所有Segment及其镜像、Master和后备Master。
  gpconfig -m => --mastervalue master_value 用于由-c 选项指定的配置参数的Master值。如果指定，则该值仅适用于Master和后备Master。该选项只能与-v一起使用。
  gpconfig -masteronly =>当被指定时，gpconfig 将仅编辑Master的postgresql.conf文件。
  gpconfig -r => --remove param_name 通过注释掉postgresql.conf文件中的项删除配置参数。
  gpconfig -l => --list 列出所有被gpconfig工具支持的配置参数。
  gpconfig -s => --show param_name 显示在Greenplum数据库系统中所有实例（Master和Segment）上使用的配置参数的值。如果实例中参数值存在差异，则工具将显示错误消息。使用-s=>选项运行gpconfig将直接从数据库中读取参数值，而不是从postgresql.conf文件中读取。如果用户使用gpconfig 在所有Segment中设置配置参数，然后运行gpconfig -s来验证更改，用户仍可能会看到以前的（旧）值。用户必须重新加载配置文件（gpstop -u）或重新启动系统（gpstop -r）以使更改生效。
  gpconfig --file => 对于配置参数，显示在Greenplum数据库系统中的所有Segment（Master和Segment）上的postgresql.conf文件中的值。如果实例中的参数值存在差异，则工具会显示一个消息。必须与-s选项一起指定。
  gpconfig --file-compare 对于配置参数，将当前Greenplum数据库值与主机（Master和Segment）上postgresql.conf文件中的值进行比较。
  gpconfig --skipvalidation 覆盖gpconfig的系统验证检查，并允许用户对任何服务器配置参数进行操作，包括隐藏参数和gpconfig无法更改的受限参数。当与-l选项（列表）一起使用时，它显示受限参数的列表。 警告： 使用此选项设置配置参数时要格外小心。
  gpconfig --verbose 在gpconfig命令执行期间显示额外的日志信息。
  gpconfig --debug 设置日志输出级别为调试级别。
  gpconfig -? | -h | --help 显示在线帮助。
  ```
  
  ```shell
  gpstart
  命令     参数   作用 
  gpstart -a => 快速启动
  gpstart -d => 指定数据目录（默认值：$MASTER_DATA_DIRECTORY）
  gpstart -q => 在安静模式下运行。命令输出不显示在屏幕，但仍然写入日志文件。
  gpstart -m => 以维护模式连接到Master进行目录维护。例如：$ PGOPTIONS='-c gp_session_role=utility' psql postgres
  gpstart -R => 管理员连接
  gpstart -v => 显示详细启动信息
  ```
  
  ```shell
  gpstop
  命令     参数   作用 
  gpstop -a => 快速停止
  gpstop -d => 指定数据目录（默认值：$MASTER_DATA_DIRECTORY）
  gpstop -m => 维护模式
  gpstop -q => 在安静模式下运行。命令输出不显示在屏幕，但仍然写入日志文件。
  gpstop -r => 停止所有实例，然后重启系统
  gpstop -u => 重新加载配置文件 postgresql.conf 和 pg_hba.conf
  gpstop -v => 显示详细启动信息
  gpstop -M fast          => 快速关闭。正在进行的任何事务都被中断。然后滚回去。
  gpstop -M immediate     => 立即关闭。正在进行的任何事务都被中止。不推荐这种关闭模式，并且在某些情况下可能导致数据库损坏需要手动恢复。
  gpstop -M smart         => 智能关闭。如果存在活动连接，则此命令在警告时失败。这是默认的关机模式。
  gpstop --host hostname  => 停用segments数据节点，不能与-m、-r、-u、-y同时使用 
  ```
  
  集群恢复
  
  ```shell
  gprecoverseg
  命令     参数   作用 
  gprecoverseg -a => 快速恢复
  gprecoverseg -F => 全量恢复
  gprecoverseg -i => 指定恢复文件
  gprecoverseg -d => 指定数据目录
  gprecoverseg -l => 指定日志文件
  gprecoverseg -r => 平衡数据
  gprecoverseg -s => 指定配置空间文件
  gprecoverseg -o => 指定恢复配置文件
  gprecoverseg -p => 指定额外的备用机
  gprecoverseg -S => 指定输出配置空间文件
  ```
  
  激活备库流程
  
  ```shell
  gpactivatestandby
  命令     参数   作用 
  gpactivatestandby -d 路径 | 使用数据目录绝对路径，默认：$MASTER_DATA_DIRECTORY
  gpactivatestandby -f | 强制激活备份主机
  gpactivatestandby -v | 显示此版本信息
  ```
  
  新增 standby节点
  
  ```shell
  gpinitstandby
  命令     参数   作用 
  gpinitstandby -s => 指定备库
  gpinitstandby -D => debug 模式
  gpinitstandby -r => 移除备用机
  ```
  
  
