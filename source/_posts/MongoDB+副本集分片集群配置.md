---
title: MongoDB副本集分片集群配置
date: 2017-02-03
categories: 
 - Linux
 - MongoDB

tags: 
 - MongoDB
 - 副本集
 - 分片集群

---

**1. 配置前准备工作**
========
**准备MongoDB程序文件**
--------
```
# wget https://fastdl.mongodb.org/linux/mongodb-linux-x86_64-rhel62-3.4.1.tgz
# tar zxf mongodb-linux-x86_64-rhel62-3.4.1.tgz
# cp -r mongodb-linux-x86_64-rhel62-3.4.1 /usr/local/
# ln -s /usr/local/mongodb-linux-x86_64-rhel62-3.4.1 /usr/local/mongodb
# ls /usr/local/mongodb
bin  GNU-AGPL-3.0  MPL-2  README  THIRD-PARTY-NOTICES
```
**为MongoDB配置环境变量**
--------
```
# vim /etc/profile.d/mongodb.sh
export PATH=/usr/local/mongodb/bin:$PATH
# source /etc/profile.d/mongodb.sh
```

<!-- more -->

**为MongoDB创建相关目录**
-------
```
# mkdir -pv /home/mongodb/shard{1,2,3}/data/
mkdir: created directory `/home/mongodb/shard1'
mkdir: created directory `/home/mongodb/shard1/data/'
mkdir: created directory `/home/mongodb/shard2'
mkdir: created directory `/home/mongodb/shard2/data/'
mkdir: created directory `/home/mongodb/shard3'
mkdir: created directory `/home/mongodb/shard3/data/'
# mkdir -pv /home/mongodb/shard{1,2,3}/config/
mkdir: created directory `/home/mongodb/shard1/config/'
mkdir: created directory `/home/mongodb/shard2/config/'
mkdir: created directory `/home/mongodb/shard3/config/'
# mkdir -pv /home/mongodb/shard{1,2,3}/log/
mkdir: created directory `/home/mongodb/shard1/log/'
mkdir: created directory `/home/mongodb/shard2/log/'
mkdir: created directory `/home/mongodb/shard3/log/'

# tree /home/mongodb
/home/mongodb
├── shard1
│   ├── config
│   ├── data
│   └── log
├── shard2
│   ├── config
│   ├── data
│   └── log
└── shard3
    ├── config
    ├── data
    └── log

12 directories, 0 files

```
**2. 配置副本集**
========
**启动MongoDB实例**
--------
```
# mongod --shardsvr --replSet sharding1 --port 27101 --dbpath /home/mongodb/shard1/data/ --pidfilepath /home/mongodb/shard1/log/sharding1_1.pid --logpath /home/mongodb/shard1/log/sharding1_1.log --logappend --fork
在生产环境中更推荐使用指定配置文件的方式来启动
# cd /home/mongodb
# vim shard1/config/shard1.conf
shardsvr = true
replSet = sharding1
port = 27101
quiet = true
dbpath = /home/mongodb/shard1/data/
pidfilepath = /home/mongodb/shard1/log/sharding1_1.pid
logpath = /home/mongodb/shard1/log/sharding1_1.log
oplogSize = 2048
directoryperdb=true
logappend = true
rest = true
fork = true
journal = true
noprealloc=true

指定配置文件启动MongoDB
# mongod --config /home/mongodb/shard1/config/shard1.conf

添加iptables规则
# iptables -I INPUT -s 192.168.1.0/24 -p tcp -j ACCEPT
# service iptables save
```
**初始化副本集（Replica Set）**
--------
```
# mongo --port 27101
> use admin
switched to db admin
> db.runCommand({"replSetInitiate" :{
... "_id":"sharding1",
... "members":[
... {"_id":1,"host":"10.1.1.148:27101"},
... {"_id":2,"host":"10.1.1.149:27101"},
... {"_id":3,"host":"10.1.1.150:27101"},
... ]}})
```
**验证副本集（Replica Sets）状态**
--------
```
sharding1:PRIMARY> rs.status()
{
	"set" : "sharding1",
	"date" : ISODate("2017-01-13T07:01:09.676Z"),
	"myState" : 1,
	"term" : NumberLong(1),
	"heartbeatIntervalMillis" : NumberLong(2000),
	"optimes" : {
		"lastCommittedOpTime" : {
			"ts" : Timestamp(1484290864, 1),
			"t" : NumberLong(1)
		},
		"appliedOpTime" : {
			"ts" : Timestamp(1484290864, 1),
			"t" : NumberLong(1)
		},
		"durableOpTime" : {
			"ts" : Timestamp(1484290864, 1),
			"t" : NumberLong(1)
		}
	},
	"members" : [
		{
			"_id" : 1,
			"name" : "10.1.1.148:27101",
			"health" : 1,
			"state" : 1,
			"stateStr" : "PRIMARY",
			"uptime" : 1169,
			"optime" : {
				"ts" : Timestamp(1484290864, 1),
				"t" : NumberLong(1)
			},
			"optimeDate" : ISODate("2017-01-13T07:01:04Z"),
			"electionTime" : Timestamp(1484290383, 1),
			"electionDate" : ISODate("2017-01-13T06:53:03Z"),
			"configVersion" : 1,
			"self" : true
		},
		{
			"_id" : 2,
			"name" : "10.1.1.149:27101",
			"health" : 1,
			"state" : 2,
			"stateStr" : "SECONDARY",
			"uptime" : 497,
			"optime" : {
				"ts" : Timestamp(1484290864, 1),
				"t" : NumberLong(1)
			},
			"optimeDurable" : {
				"ts" : Timestamp(1484290864, 1),
				"t" : NumberLong(1)
			},
			"optimeDate" : ISODate("2017-01-13T07:01:04Z"),
			"optimeDurableDate" : ISODate("2017-01-13T07:01:04Z"),
			"lastHeartbeat" : ISODate("2017-01-13T07:01:09.543Z"),
			"lastHeartbeatRecv" : ISODate("2017-01-13T07:01:09.460Z"),
			"pingMs" : NumberLong(0),
			"syncingTo" : "10.1.1.148:27101",
			"configVersion" : 1
		},
		{
			"_id" : 3,
			"name" : "10.1.1.150:27101",
			"health" : 1,
			"state" : 2,
			"stateStr" : "SECONDARY",
			"uptime" : 497,
			"optime" : {
				"ts" : Timestamp(1484290864, 1),
				"t" : NumberLong(1)
			},
			"optimeDurable" : {
				"ts" : Timestamp(1484290864, 1),
				"t" : NumberLong(1)
			},
			"optimeDate" : ISODate("2017-01-13T07:01:04Z"),
			"optimeDurableDate" : ISODate("2017-01-13T07:01:04Z"),
			"lastHeartbeat" : ISODate("2017-01-13T07:01:09.543Z"),
			"lastHeartbeatRecv" : ISODate("2017-01-13T07:01:09.456Z"),
			"pingMs" : NumberLong(0),
			"syncingTo" : "10.1.1.148:27101",
			"configVersion" : 1
		}
	],
	"ok" : 1
}
```
**三台主机操作一致。**
**其余两个副本集的设置同上。**
**3. 配置分片集群**
========
**为config server创建相关目录**
--------
```
# mkdir -pv /home/mongodb/configsvr/{data,config,log}
mkdir: created directory `/home/mongodb/configsvr'
mkdir: created directory `/home/mongodb/configsvr/data'
mkdir: created directory `/home/mongodb/configsvr/config'
mkdir: created directory `/home/mongodb/configsvr/log'
# tree /home/mongodb
/home/mongodb
├── configsvr
│   ├── config
│   ├── data
│   └── log
```
**启动config server实例**
--------
```
# vim /home/mongodb/configsvr/config/configsvr.conf
configsvr = true
replSet = configdb
dbpath = /home/mongodb/configsvr/data/
port = 27301
logpath = /home/mongodb/configsvr/log/dbconfig.log
pidfilepath = /home/mongodb/configsvr/log/configdb.pid
rest = true
journal = true
logappend = true
fork = true

# mongod --config /home/mongodb/configsvr/config/configsvr.conf
```
**为config server 配置副本集**
--------
```
因为mongodb 3.2版本以后要求配置服务器必须也是副本集，所以我们要给config server也建立一个副本集
# mongo --port 27301
> use admin
switched to db admin
> db.runCommand({"replSetInitiate" :{
... "_id":"configdb",
... "members":[
... {"_id":1,"host":"10.1.1.148:27301"},
... {"_id":2,"host":"10.1.1.149:27301"},
... {"_id":3,"host":"10.1.1.150:27301"},
... ]}})
{ "ok" : 1 }
```
**为mongos创建相关目录**
--------
```
# mkdir -pv /home/mongodb/mongos/{data,config,log}
mkdir: created directory `/home/mongodb/mongos'
mkdir: created directory `/home/mongodb/mongos/data'
mkdir: created directory `/home/mongodb/mongos/config'
mkdir: created directory `/home/mongodb/mongos/log'
# tree /home/mongodb
/home/mongodb
├── mongos
│   ├── config
│   ├── data
│   └── log
```
**启动mongos实例**
--------
```
# vim /home/mongodb/mongos/config/mongos.conf
configdb = configdb/10.1.1.148:27301,10.1.1.149:27301,10.1.1.150:27301
port = 28885
logpath = /home/mongodb/mongos/log/mongos.log
pidfilepath = /home/mongodb/mongos/log/mongos.pid
logappend = true
fork = true

# mongos --config /home/mongodb/mongos/config/mongos.conf
```
**登录mongos进程，配置Shard Cluster**
--------
```
# mongo --port 28885 admin
mongos> db.runCommand({addshard:"sharding1/10.1.1.148:27101,10.1.1.149:27101,10.1.1.150:27101"});
{ "shardAdded" : "sharding1", "ok" : 1 }
mongos> db.runCommand({addshard:"sharding2/10.1.1.148:27102,10.1.1.149:27102,10.1.1.150:27102"});
{ "shardAdded" : "sharding2", "ok" : 1 }
mongos> db.runCommand({addshard:"sharding3/10.1.1.148:27103,10.1.1.149:27103,10.1.1.150:27103"});
{ "shardAdded" : "sharding3", "ok" : 1 }
```


