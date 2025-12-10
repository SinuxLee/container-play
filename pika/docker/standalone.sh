#!/usr/bin/env bash

mkdir -p pika/{conf,db,log}
cat > pika/conf/pika.conf <<'EOF'
# Pika port
port : 9221

# Thread Number
# pika是多线程的, 该参数能够配置pika的线程数量, 不建议配置值超过部署服务器的CPU核心数量 
thread-num : 1

# Thread Pool Size
# 处理命令用户请求命令线程池的大小
thread-pool-size : 12

# Sync Thread Number
# sync 主从同步时候从库执行主库传递过来命令的线程数量
sync-thread-num : 6

# sync 处理线程的任务队列大小, 不建议修改
sync-buffer-size : 10

# Pika log path
# Pika日志目录, 用于存放INFO, WARNING, ERROR日志以及用于同步的binlog(write2fine)文件
log-path : ./log/

# Pika db path
# Pika数据目录
db-path : ./db/

# Pika write-buffer-size
# Pika 底层引擎的write_buffer_size配置, 设置越大写入性能越好但会在buffer刷盘时带来更大的IO负载, 请依据使用场景合理配置
write-buffer-size : 268435456

# Pika timeout
# Pika 的连接超时时间配置, 单位为秒, 当连接无请求时(进入sleep状态)开始从配置时间倒计时, 当倒计时为0时pika将强行
# 断开该连接, 可以通过合理配置该参数避免可能出现的pika连接数用尽问题, 该参数默认值为60
timeout : 60

# Requirepass
# 密码管理员密码, 默认为空, 如果该参数与下方的userpass参数相同(包括同时为空), 则userpass参数将自动失效, 所有用户均为
# 管理员身份不受userblacklist参数的限制
requirepass : adminpass

# Masterauth
# 同步验证密码, 用于slave(从库)连接master(主库)请求同步时进行验证, 该参数需要与master(主库)的requirepass一致
masterauth :

# Userpass
# 用户密码, 默认为空, 如果该参数与上方的userpass参数相同(包括同时为空), 则本参数将自动失效, 所有用户均为管理员身份不
# 受userblacklist参数的限制
userpass :

# User Blacklist
# 指令黑名单, 能够限制通过userpass登录的用户, 这些用户将不能使用黑名单中的指令, 指令之间使用","隔开, 默认为空
# 建议将高风险命令配置在该参数中
userblacklist : FLUSHALL, SHUTDOWN, KEYS, CONFIG

# if this option is set to 'classic', that means pika support multiple DB, in
# this mode, option databases enable
# if this option is set to 'sharding', that means pika support multiple Table, you
# can specify slot num for each table, in this mode, option default-slot-num enable
# Pika instance mode [classic | sharding]
# 分为经典模式和分片模式，[classic | sharding]，经典模式中支持多db的配置
instance-mode : classic

# Set the number of databases. The default database is DB 0, you can select
# a different one on a per-connection basis using SELECT <dbid> where
# dbid is a number between 0 and 'databases' - 1, limited in [1, 8]
# 经典模式下下指定db的数量，使用方式和redis一致
databases : 1

# default slot number each table in sharding mode
# 分片模式下每一个table中默认的slot数量
default-slot-num : 1024

# Dump Prefix
# Pika的dump文件名称前缀, bgsave后生成的文件将以该前缀命名
dump-prefix :

# daemonize  [yes | no] 
# 守护进程模式  [yes | no]
#daemonize : yes
 
# slotmigrate  [yes | no], pika3.0.0暂不支持该参数
#slotmigrate : no

# Dump Path
# Pika dump目录设置, bgsave后生成的文件将存放在该目录中
dump-path : ./dump/

# Expire-dump-days
# dump目录过期时间, 单位为天, 默认为0即永不过期
dump-expire : 0

# pidfile Path
# pidfile Path pid文件目录
pidfile : ./pika.pid

# Max Connection 
# pika最大连接数配置参数
maxclients : 20000

# the per file size of sst to compact, defalut is 2M
# rocks-db的sst文件体积, sst文件是层级的, 文件越小, 速度越快, 合并代价越低, 但文件数量就会超多, 而文件越大, 速度相对变慢, 合并代价大, 但文件数量会很少, 默认是 20M
target-file-size-base : 20971520

# Expire-logs-days
# binlog(write2file)文件保留时间, 7天, 最小为1, 超过7天的文件会被自动清理
expire-logs-days : 7

# Expire-logs-nums 
# binlog(write2file)文件最大数量, 200个, 最小为10, 超过200个就开始自动清理, 始终保留200个
expire-logs-nums : 10

# Root-connection-num 
# root用户连接保证数量：2个, 即时Max Connection用完, 该参数也能确保本地（127.0.0.1）有2个连接可以同来登陆pika
root-connection-num : 2

# Slowlog-write-errorlog
slowlog-write-errorlog : yes

# Slowlog-log-slower-than
# 慢日志记录时间, 单位为微秒, pika的慢日志记录在pika-ERROR.log中, pika没有类似redis slow log的慢日志提取api
slowlog-log-slower-than : 10000

# Slowlog-max-len
slowlog-max-len : 128

# slave是否是只读状态(yes/no, 1/0)
# slave-read-only : 0

# Pika db sync path
# Pika db 同步路径配置参数
db-sync-path : ./dbsync/
# db sync speed(MB) max is set to 1024MB, min is set to 0, and if below 0 or above 1024, the value will be adjust to 1024
# 该参数能够控制全量同步时的传输速度, 合理配置该参数能够避免网卡被用尽, 该参数范围为1~125, 意为:1mb~125mb，当该参数
# 被配置为小于0或大于125时, 该参数会被自动配置为125
db-sync-speed : -1

# The slave priority
slave-priority : 100

# network interface
# 指定网卡
# network-interface : eth1

# replication
# 同步参数配置, 适用于从库节点(slave), 该参数格式为ip:port, 例如192.168.1.2:6666, 启动后该示例会自动向192.168.1.2的
# 6666端口发送同步请求
# slaveof : master-ip:master-port

# CronTask, format 1: start-end/ratio, like 02-04/60, pika will check to schedule compaction between 2 to 4 o'clock everyday
#                   if the freesize/disksize > 60%.
#           format 2: week/start-end/ratio, like 3/02-04/60, pika will check to schedule compaction between 2 to 4 o'clock
#                   every wednesday, if the freesize/disksize > 60%.
#           NOTICE: if compact-interval is set, compact-cron will be mask and disable.
#
#compact-cron : 3/02-04/60

# Compact-interval, format: interval/ratio, like 6/60, pika will check to schedule compaction every 6 hours,
#                           if the freesize/disksize > 60%. NOTICE:compact-interval is prior than compact-cron;
#compact-interval :

# server-id for hub
# 配置双主或Hub需要的server id, 不使用双主或Hub请忽略该参数
server-id : 1

# 双主配置, 不使用双主请忽略以下配置

# 双主对端Ip
# double-master-ip :

# 双主对端Port
# double-master-port :

# 双主对端server id
# double-master-server-id :
 
# 自动全量compact, 通过配置的参数每天定时触发一次自动全量compact, 特别适合存在多数据结构大量过期删除、key名称复用的场景
# 参数格式为:"启动时间(小时)-结束时间(小时)/磁盘空余空间百分比", 例如你需要配置一个每天在凌晨3点~4点之间自动compact的任务
# 同时该任务仅仅在磁盘空余空间不低于30%的时候执行, 那么应配置为:03-04/30, 该参数默认为空
# compact-cron :

# 自动全量compact, 该参与与compact-cron的区别为, compact-cron每天仅在指定时间段执行, 而compact-interval则以配置时间为周期
# 循环执行, 例如你需要配置一个每4小时执行一次的自动compact任务, 同时该任务仅仅在磁盘空余空间不低于30%的时候执行, 那么该参
# 数应配置为:4/30, 该参数默认为空
# compact-interval :

# 从库实例权重设置, 仅配合哨兵使用,无其它功能, 权重低的slave会优先选举为主库, 该参数默认为0(不参与选举)
# slave-priority :

# 该参数仅适用于pika跨版本同步时不同版本的binlog能够兼容并成功解析, 该参数可配置为[new | old]
# 当该参数被配置为new时, 该实例仅能作为3.0.0及以上版本pika的从库, 与pika2.3.3~2.3.5不兼容
# 当该参数被配置为old时, 该时候仅能作为2.3.3~2.3.5版本pika的从库, 与pika3.0.0及以上版本不兼容
# 该参数默认值为new, 该参数可在没有配置同步关系的时候通过config set动态调整, 一旦配置了同步关系则不可动态修改
# 需要先执行slaveof no one关闭同步配置, 之后即可通过config set动态修改
# identify-binlog-type : new


###################
#Critical Settings#
#    危险参数      #
###################
# write_binlog  [yes | no]
write-binlog : yes
# binlog file size: default is 100M,  limited in [1K, 2G]
# write2file文件体积, 默认为100MB, 一旦启动不可修改,  limited in [1K, 2G]
binlog-file-size : 104857600
# Automatically triggers a small compaction according statistics
# Use the cache to store up to 'max-cache-statistic-keys' keys
# if 'max-cache-statistic-keys' set to '0', that means turn off the statistics function
# it also doesn't automatically trigger a small compact feature
max-cache-statistic-keys : 0
# When 'delete' or 'overwrite' a specific multi-data structure key 'small-compaction-threshold' times,
# a small compact is triggered automatically, default is 5000, limited in [1, 100000]
small-compaction-threshold : 5000
# If the total size of all live memtables of all the DBs exceeds
# the limit, a flush will be triggered in the next DB to which the next write
# is issued.
max-write-buffer-size : 10737418240
# Compression

# 压缩方式[snappy | zlib | none]默认为snappy, 一旦启动不可修改
compression : snappy

# max-background-flushes: default is 1, limited in [1, 4]
# 指定后台flush线程数量, 默认为1, 范围为[1, 4]
max-background-flushes : 1

# max-background-compactions: default is 2, limited in [1, 8]
# 指定后台压缩线程数量, 默认为1, 范围为[1, 8]
max-background-compactions : 2

# max-cache-files default is 5000
# DB可以使用的打开文件的数量, 默认为5000
max-cache-files : 5000

# max_bytes_for_level_multiplier: default is 10, you can change it to 5
# pika引擎中层级因子, 用于控制每个层级与上一层级总容量的倍数关系, 默认为10(倍), 允许调整为5(倍) 
max-bytes-for-level-multiplier : 10
# BlockBasedTable block_size, default 4k
# block-size: 4096
# block LRU cache, default 8M, 0 to disable
# block-cache: 8388608
# whether the block cache is shared among the RocksDB instances, default is per CF
# share-block-cache: no
# whether or not index and filter blocks is stored in block cache
# cache-index-and-filter-blocks: no
# when set to yes, bloomfilter of the last level will not be built
# optimize-filters-for-hits: no
# https://github.com/facebook/rocksdb/wiki/Leveled-Compaction#levels-target-size
# level-compaction-dynamic-level-bytes: no

EOF

docker run -d \
-p 9221:9221 \
--name pika \
--hostname pika \
-v $PWD/pika/conf:/pika/conf:ro \
-v $PWD/pika/db:/pika/db \
-v $PWD/pika/log:/pika/log \
-v /etc/localtime:/etc/localtime \
--restart=always \
--privileged=true \
pikadb/pika:v3.4.0
