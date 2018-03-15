---
title: Redis Cluster部署配置
date: 2017-02-02
categories: 
 - Linux
 - Redis

tags: 
 - redis
 - redis-cluster

---

**1. 配置前准备工作**
========
**部署规划**
--------
```
集群使用三台服务器，每服务器上分别部署两个实例（端口监听6379、7379），一共6个实例来组建集群。
redis安装路径
/usr/local/redis3
链接至
/usr/local/redis
redis数据存放位置
/home/redis/{6379,7379}/data
redis日志文件、pid文件位置
/home/redis/{6379,7379}/log
redis配置文件位置
/home/redis/{6379,7379}/config
```
**准备redis安装程序**
--------
```
# wget http://download.redis.io/releases/redis-3.2.6.tar.gz
# tar zxf redis-3.2.6.tar.gz
```
**为redis创建相关目录**
--------
```
redis安装目录
# mkdir -pv /usr/local/redis3
redis数据目录
redis日志文件、PID文件、配置文件目录
# mkdir -pv /home/redis/{6379,7379}/{data,config,log}
mkdir: created directory `/home/redis'
mkdir: created directory `/home/redis/6379'
mkdir: created directory `/home/redis/6379/data'
mkdir: created directory `/home/redis/6379/config'
mkdir: created directory `/home/redis/6379/log'
mkdir: created directory `/home/redis/7379'
mkdir: created directory `/home/redis/7379/data'
mkdir: created directory `/home/redis/7379/config'
mkdir: created directory `/home/redis/7379/log'
```
**配置相应iptables规则**
```
# iptables -I INPUT -s 10.1.1.0/24 -p tcp -j ACCEPT
# service iptables save
```
**2. 安装redis并配置实例**
========
**安装redis**
--------
```
解决依赖关系
# yum install -y gcc*
# cd redis-3.2.6
# make
# make test
cd src && make test
make[1]: Entering directory `/home/soft/redis/redis-3.2.6/src'
You need tcl 8.5 or newer in order to run the Redis test
make[1]: *** [test] Error 1
make[1]: Leaving directory `/home/soft/redis/redis-3.2.6/src'
make: *** [test] Error 2
报错，提示需要tcl 8.5或以上版本支持。
# yum install -y tcl
继续make test，通过。

如果继续报错：
*** [err]: Test replication partial resync: ok psync (diskless: yes, reconnect: 1) in tests/integration/replication-psync.tcl
只需要以单核运行make test就行了
# taskset -c 1 sudo make test

指定目录安装
# make PREFIX=/usr/local/redis3 install
# ln -s /usr/local/redis3 /usr/local/redis
# ls /usr/local/redis
bin
```
**配置环境变量**
--------
```
# vim /etc/profile.d/redis.sh
export PATH=/usr/local/redis/bin:$PATH
# source /etc/profile.d/redis.sh
```
**准备redis配置文件**
--------
```
# vim /home/redis/6379/config/redis-6379.conf
bind 10.1.1.148
protected-mode no
port 6379
tcp-backlog 511
timeout 0
tcp-keepalive 0
daemonize yes
supervised no
pidfile /home/redis/6379/log/redis_6379.pid
loglevel notice
logfile "/home/redis/6379/log/redis-6379.log"
databases 16
save 900 1
save 300 10
save 60 10000
stop-writes-on-bgsave-error yes
rdbcompression yes
rdbchecksum yes
dbfilename dump.rdb
dir /home/redis/6379/data/
slave-serve-stale-data yes
slave-read-only yes
repl-diskless-sync no
repl-diskless-sync-delay 5
repl-disable-tcp-nodelay no
slave-priority 100
maxclients 10000
appendonly yes
appendfilename "appendonly.aof"
appendfsync everysec
no-appendfsync-on-rewrite no
auto-aof-rewrite-percentage 100
auto-aof-rewrite-min-size 64mb
aof-load-truncated yes
lua-time-limit 5000
cluster-enabled yes #（开启集群）
cluster-config-file /home/redis/6379/config/nodes-6379.conf #（此配置文件在首次启动时自动生成）
cluster-node-timeout 15000
cluster-slave-validity-factor 10
cluster-migration-barrier 1
cluster-require-full-coverage yes
slowlog-log-slower-than 10000
slowlog-max-len 128
latency-monitor-threshold 0
notify-keyspace-events ""
hash-max-ziplist-entries 512
hash-max-ziplist-value 64
list-max-ziplist-size -2
list-compress-depth 0
set-max-intset-entries 512
zset-max-ziplist-entries 128
zset-max-ziplist-value 64
hll-sparse-max-bytes 3000
activerehashing yes
client-output-buffer-limit normal 0 0 0
client-output-buffer-limit slave 256mb 64mb 60
client-output-buffer-limit pubsub 32mb 8mb 60
hz 10
aof-rewrite-incremental-fsync yes

# cp /home/redis/6379/config/redis-6379.conf /home/redis/7379/config/redis-7379.conf
将6379的配置文件复制到7379中，并修改相应的路径及端口号。
# sed -i 's/6379/7379/g' /home/redis/7379/config/redis-7379.conf

在其余几台服务器上同样操作，记住务必要修改相应端口号及绑定IP。
```
**启动redis实例**
--------
```
# redis-server /home/redis/6379/config/redis-6379.conf
# redis-server /home/redis/7379/config/redis-7379.conf
```
**3. 创建redis-cluster集群**
========
**使用redis-trib.rb来创建cluster集群**
```
redis官方提供了一个工具/home/soft/redis/redis-3.2.6/src/redis-trib.rb用来创建集群。
# /home/soft/redis/redis-3.2.6/src/redis-trib.rb create --replicas 1 10.1.1.148:6379 10.1.1.149:6379 10.1.1.150:6379 10.1.1.148:7379 10.1.1.149:7379 10.1.1.150:7379
/usr/bin/env: ruby: No such file or directory
有报错，因为这是一个ruby程序，必须安装ruby才可以执行
```
**安装ruby及相关支持**
```
# yum -y install ruby ruby-devel rubygems rpm-build
# gem install redis
此处可指定安装对应版本，如
# gem install redis --version 3.2.2
```
**创建redis-cluster集群**
```
# /home/soft/redis/redis-3.2.6/src/redis-trib.rb create --replicas 1 10.1.1.148:6379 10.1.1.149:6379 10.1.1.150:6379 10.1.1.148:7379 10.1.1.149:7379 10.1.1.150:7379
>>> Creating cluster
>>> Performing hash slots allocation on 6 nodes...
Using 3 masters:
10.1.1.150:6379
10.1.1.149:6379
10.1.1.148:6379
Adding replica 10.1.1.149:7379 to 10.1.1.150:6379
Adding replica 10.1.1.150:7379 to 10.1.1.149:6379
Adding replica 10.1.1.148:7379 to 10.1.1.148:6379
M: 4b37935462a37c9817f9c90877b07a8984c8c5d4 10.1.1.148:6379
   slots:10923-16383 (5461 slots) master
M: a96f7c1a1b9fa6c128549cbef80e7b021c8c2e57 10.1.1.149:6379
   slots:5461-10922 (5462 slots) master
M: cffe855dfc88781443af94d65a8b25b6bbf381fd 10.1.1.150:6379
   slots:0-5460 (5461 slots) master
S: 96ac7786eb3317048f82be33024c954794a75230 10.1.1.148:7379
   replicates 4b37935462a37c9817f9c90877b07a8984c8c5d4
S: 03bd2483ab51191208bfdbc6781e8910018980f1 10.1.1.149:7379
   replicates cffe855dfc88781443af94d65a8b25b6bbf381fd
S: 0ba60ec12c581896898fe0504009cdb494f61bc6 10.1.1.150:7379
   replicates a96f7c1a1b9fa6c128549cbef80e7b021c8c2e57
Can I set the above configuration? (type 'yes' to accept): yes
/usr/lib/ruby/gems/1.8/gems/redis-3.3.2/lib/redis/connection/ruby.rb:111:in `_write_to_socket': Connection timed out (Redis::TimeoutError)
	from /usr/lib/ruby/gems/1.8/gems/redis-3.3.2/lib/redis/connection/ruby.rb:131:in `write'
	from /usr/lib/ruby/gems/1.8/gems/redis-3.3.2/lib/redis/connection/ruby.rb:130:in `loop'
	from /usr/lib/ruby/gems/1.8/gems/redis-3.3.2/lib/redis/connection/ruby.rb:130:in `write'
	from /usr/lib/ruby/gems/1.8/gems/redis-3.3.2/lib/redis/connection/ruby.rb:374:in `write'
	from /usr/lib/ruby/gems/1.8/gems/redis-3.3.2/lib/redis/client.rb:271:in `write'
	from /usr/lib/ruby/gems/1.8/gems/redis-3.3.2/lib/redis/client.rb:250:in `io'
	from /usr/lib/ruby/gems/1.8/gems/redis-3.3.2/lib/redis/client.rb:269:in `write'
	from /usr/lib/ruby/gems/1.8/gems/redis-3.3.2/lib/redis/client.rb:228:in `process'
	from /usr/lib/ruby/gems/1.8/gems/redis-3.3.2/lib/redis/client.rb:222:in `each'
	from /usr/lib/ruby/gems/1.8/gems/redis-3.3.2/lib/redis/client.rb:222:in `process'
	from /usr/lib/ruby/gems/1.8/gems/redis-3.3.2/lib/redis/client.rb:367:in `ensure_connected'
	from /usr/lib/ruby/gems/1.8/gems/redis-3.3.2/lib/redis/client.rb:221:in `process'
	from /usr/lib/ruby/gems/1.8/gems/redis-3.3.2/lib/redis/client.rb:306:in `logging'
	from /usr/lib/ruby/gems/1.8/gems/redis-3.3.2/lib/redis/client.rb:220:in `process'
	from /usr/lib/ruby/gems/1.8/gems/redis-3.3.2/lib/redis/client.rb:120:in `call'
	from /usr/lib/ruby/gems/1.8/gems/redis-3.3.2/lib/redis.rb:2705:in `method_missing'
	from /usr/lib/ruby/gems/1.8/gems/redis-3.3.2/lib/redis.rb:58:in `synchronize'
	from /usr/lib/ruby/1.8/monitor.rb:242:in `mon_synchronize'
	from /usr/lib/ruby/gems/1.8/gems/redis-3.3.2/lib/redis.rb:58:in `synchronize'
	from /usr/lib/ruby/gems/1.8/gems/redis-3.3.2/lib/redis.rb:2704:in `method_missing'
	from /home/soft/redis/redis-3.2.6/src/redis-trib.rb:212:in `flush_node_config'
	from /home/soft/redis/redis-3.2.6/src/redis-trib.rb:776:in `flush_nodes_config'
	from /home/soft/redis/redis-3.2.6/src/redis-trib.rb:775:in `each'
	from /home/soft/redis/redis-3.2.6/src/redis-trib.rb:775:in `flush_nodes_config'
	from /home/soft/redis/redis-3.2.6/src/redis-trib.rb:1296:in `create_cluster_cmd'
	from /home/soft/redis/redis-3.2.6/src/redis-trib.rb:1701:in `send'
	from /home/soft/redis/redis-3.2.6/src/redis-trib.rb:1701
	
出现报错：/usr/lib/ruby/gems/1.8/gems/redis-3.3.2/lib/redis/connection/ruby.rb:111:in `_write_to_socket': Connection timed out (Redis::TimeoutError)
搜索了一下，发现是gem安装的redis库版本太高。
# gem list
*** LOCAL GEMS ***
redis (3.3.2)

卸载并使用3.0的gem就OK了。
# gem uninstall redis --version 3.3.2
Successfully uninstalled redis-3.3.2
# gem install redis --version 3.0.0
Successfully installed redis-3.0.0
1 gem installed
Installing ri documentation for redis-3.0.0...
Installing RDoc documentation for redis-3.0.0...
# gem list
*** LOCAL GEMS ***
redis (3.0.0)

重新执行命令创建集群
继续报错：/usr/lib/ruby/gems/1.8/gems/redis-3.0.0/lib/redis/client.rb:79:in `call': ERR Slot 11291 is already busy (Redis::CommandError)
这是因为之前创建集群没有成功,需要将nodes.conf和dir里面的文件全部删除
# rm -rf 6379/config/nodes-6379.conf
# rm -rf 6379/data/*
# rm -rf 7379/config/nodes-7379.conf
# rm -rf 7379/data/*
# redis-cli -p 6379 shutdown
# redis-cli -p 7379 shutdown
# redis-server /home/redis/6379/config/redis-6379.conf
# redis-server /home/redis/7379/config/redis-7379.conf

报错：一直卡在Waiting for the cluster to join.....................................
问题原因不明，但是按照网上的解决办法是，在redis配置文件中bind一行只绑定一个内网IP地址即可，不要绑定本地回环地址127.0.0.1
# vim /home/redis/6379/config/redis-6379.conf
bind 10.1.1.148

创建集群成功
# /home/soft/redis/redis-3.2.6/src/redis-trib.rb create --replicas 1 10.1.1.148:6379 10.1.1.149:6379 10.1.1.150:6379 10.1.1.148:7379 10.1.1.149:7379 10.1.1.150:7379
>>> Creating cluster
>>> Performing hash slots allocation on 6 nodes...
Using 3 masters:
10.1.1.149:6379
10.1.1.148:6379
10.1.1.150:6379
Adding replica 10.1.1.148:7379 to 10.1.1.149:6379
Adding replica 10.1.1.149:7379 to 10.1.1.148:6379
Adding replica 10.1.1.150:7379 to 10.1.1.150:6379
M: ce3a2498a81f450b3d648bc1ede7c82fcac87cf2 10.1.1.148:6379
   slots:5461-10922 (5462 slots) master
M: 74719e18073c6ac08da0a5608e7986d057e51ee4 10.1.1.149:6379
   slots:0-5460 (5461 slots) master
M: 3c2b327b2b56ddf07fc4040061f95dd6458b5154 10.1.1.150:6379
   slots:10923-16383 (5461 slots) master
S: 0d43b62b9ce2241147376574280e339b1fc3a97b 10.1.1.148:7379
   replicates 74719e18073c6ac08da0a5608e7986d057e51ee4
S: 40a7736a56fe9671a79eb4e392a3669a4797c4d3 10.1.1.149:7379
   replicates ce3a2498a81f450b3d648bc1ede7c82fcac87cf2
S: b6e2e6c8093bfa92d49c6f3771316ca1c5304c01 10.1.1.150:7379
   replicates 3c2b327b2b56ddf07fc4040061f95dd6458b5154
Can I set the above configuration? (type 'yes' to accept): yes
>>> Nodes configuration updated
>>> Assign a different config epoch to each node
>>> Sending CLUSTER MEET messages to join the cluster
Waiting for the cluster to join..
>>> Performing Cluster Check (using node 10.1.1.148:6379)
M: ce3a2498a81f450b3d648bc1ede7c82fcac87cf2 10.1.1.148:6379
   slots:5461-10922 (5462 slots) master
   1 additional replica(s)
S: 40a7736a56fe9671a79eb4e392a3669a4797c4d3 10.1.1.149:7379
   slots: (0 slots) slave
   replicates ce3a2498a81f450b3d648bc1ede7c82fcac87cf2
S: b6e2e6c8093bfa92d49c6f3771316ca1c5304c01 10.1.1.150:7379
   slots: (0 slots) slave
   replicates 3c2b327b2b56ddf07fc4040061f95dd6458b5154
M: 74719e18073c6ac08da0a5608e7986d057e51ee4 10.1.1.149:6379
   slots:0-5460 (5461 slots) master
   1 additional replica(s)
M: 3c2b327b2b56ddf07fc4040061f95dd6458b5154 10.1.1.150:6379
   slots:10923-16383 (5461 slots) master
   1 additional replica(s)
S: 0d43b62b9ce2241147376574280e339b1fc3a97b 10.1.1.148:7379
   slots: (0 slots) slave
   replicates 74719e18073c6ac08da0a5608e7986d057e51ee4
[OK] All nodes agree about slots configuration.
>>> Check for open slots...
>>> Check slots coverage...
[OK] All 16384 slots covered.
```
**检查集群状态**
```
# /home/soft/redis/redis-3.2.6/src/redis-trib.rb check 10.1.1.148:6379
>>> Performing Cluster Check (using node 10.1.1.148:6379)
M: ce3a2498a81f450b3d648bc1ede7c82fcac87cf2 10.1.1.148:6379
   slots:5461-10922 (5462 slots) master
   1 additional replica(s)
S: 40a7736a56fe9671a79eb4e392a3669a4797c4d3 10.1.1.149:7379
   slots: (0 slots) slave
   replicates ce3a2498a81f450b3d648bc1ede7c82fcac87cf2
S: b6e2e6c8093bfa92d49c6f3771316ca1c5304c01 10.1.1.150:7379
   slots: (0 slots) slave
   replicates 3c2b327b2b56ddf07fc4040061f95dd6458b5154
M: 74719e18073c6ac08da0a5608e7986d057e51ee4 10.1.1.149:6379
   slots:0-5460 (5461 slots) master
   1 additional replica(s)
M: 3c2b327b2b56ddf07fc4040061f95dd6458b5154 10.1.1.150:6379
   slots:10923-16383 (5461 slots) master
   1 additional replica(s)
S: 0d43b62b9ce2241147376574280e339b1fc3a97b 10.1.1.148:7379
   slots: (0 slots) slave
   replicates 74719e18073c6ac08da0a5608e7986d057e51ee4
[OK] All nodes agree about slots configuration.
>>> Check for open slots...
>>> Check slots coverage...
[OK] All 16384 slots covered.

```
**测试redis集群**
```
# redis-cli -h 10.1.1.148 -p 6379
10.1.1.148:6379> set test test01
OK
10.1.1.148:6379> get test
"test01"
# redis-cli -h 10.1.1.149 -p 7379
10.1.1.149:7379> get test
(error) MOVED 6918 10.1.1.148:6379
发现在另一节点上无法get，因为Redis集群的数据是根据插槽值来设置进具体的节点中的.但是如果这个key的插槽值不是在当前redis实例的话,他就需要进行重定向.
所以redis-cli提供可一个-c参数用来连接集群，指定了这个参数之后,redis-cli会根据插槽值做一个重定向,连接到指定的redis实例上面。
# redis-cli -c -h 10.1.1.149 -p 7379
10.1.1.149:7379> get test
-> Redirected to slot [6918] located at 10.1.1.148:6379
"test01"
```



