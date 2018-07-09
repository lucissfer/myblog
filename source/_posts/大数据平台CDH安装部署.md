---
title: 大数据平台CDH安装部署
date: 2018-07-09
categories: 
 - Linux
 - Centos
 - 大数据

tags: 
 - 大数据
 - CDH
 - Hadoop

---

> 因为业务需要了解大数据平台CDH的部署，找了三台虚拟机简单的安装部署一下，踩了一遍坑，留个文档记录一下。

**1. 服务器规划**
======
```shell
集群规划三台服务器，一台namenode，两台datanode，规划如下：
namenode
192.168.3.131
node-01
192.168.3.132
node-02
192.168.3.133

服务器操作系统均为Centos 7 x86_64
```
**2. 安装前预配置**
======
2.1 关闭防火墙、SELINUX
------
关闭防火墙
```shell
因为是测试环境，为方便起见，直接关闭防火墙，生产环境中最好还是开启防火墙，开放相应端口就行了，或者直接在防火墙中配置集群内服务器白名单
# systemctl stop firewalld
# systemctl disable firewalld
```
关闭SELINUX
```shell
SELINUX建议一定要关掉，配置太麻烦了，而且容易踩坑，官方也建议关掉
# setenforce 0
# sed -i 's/SELINUX=enforcing/#SELINUX=enforcing\nSELINUX=disabled/g' /etc/sysconfig/selinux
```

<!-- more -->

2.2 配置CM源
------
```shell
# wget -O /etc/yum.repos.d/cloudera-manager.repo http://archive.cloudera.com/cm5/redhat/7/x86_64/cm/cloudera-manager.repo
# wget -O /etc/yum.repos.d/cloudera-cdh5.repo https://archive.cloudera.com/cdh5/redhat/7/x86_64/cdh/cloudera-cdh5.repo
```
2.3 安装JDK
------
```shell
CDH对JDK版本有要求，建议1.8以上
# rpm -ivh jdk-8u171-linux-x64.rpm
```
2.4 修改hosts文件
------
```shell
# vim /etc/hosts
127.0.0.1   localhost localhost.localdomain localhost4 localhost4.localdomain4
::1         localhost localhost.localdomain localhost6 localhost6.localdomain6
192.168.3.131 namenode
192.168.3.132 node-01
192.168.3.133 node-02
```
2.5 配置集群时钟同步
------
**CDH服务集群一定要配置时间同步，否则集群会持续报警时钟偏移，此处我用的是chrony**
以namenode做服务器，node节点做客户端
服务端
```shell
# yum install -y chrony
# vim /etc/chrony.conf
server 192.168.3.131 iburst
服务端配置与自己同步
```

客户端
```shell
# yum install -y chrony
# vim /etc/chrony.conf
server 192.168.3.131 iburst
客户端配置与服务端同步
```

重启所有服务器chrony服务
```shell
# systemctl restart chronyd
```

验证同步
```shell
# chronyc -n sources
```
2.6 安装配置MariaDB服务
------
CDH集群部署需要数据库服务支持，目前支持Oracle/MySQL(MariaDB)/PostgreSQL，这里我用的MariaDB，只需要在主节点(namenode)上安装即可
```shell
# yum install -y mariadb-server mariadb
```
启动mariadb
```shell
# systemctl start mariadb
```
初始化mariadb
```shell
# /usr/bin/mysql_secure_installation
root
123456
```
创建各个服务需要的库
```shell
create database hive DEFAULT CHARSET utf8 COLLATE utf8_general_ci;
create database amon DEFAULT CHARSET utf8 COLLATE utf8_general_ci;
create database hue DEFAULT CHARSET utf8 COLLATE utf8_general_ci;
create database monitor DEFAULT CHARSET utf8 COLLATE utf8_general_ci;
create database oozie DEFAULT CHARSET utf8 COLLATE utf8_general_ci;
create database am DEFAULT CHARSET utf8 COLLATE utf8_general_ci;
create database cm DEFAULT CHARSET utf8 COLLATE utf8_general_ci;
create database rm DEFAULT CHARSET utf8 COLLATE utf8_general_ci;

这里创建的库名最好与你后面要安装的服务保持一致
```
2.7 安装jdbc驱动
------
```shell
# yum install -y mysql-connector-java
```
**3. 安装Cloudera Manager服务**
======
主节点服务器
```shell
# yum install -y cloudera-manager-server
```
从节点服务器
```shell
# yum install -y cloudera-manager-agent
```
安装oracle-j2sdk1.7
```shell
# yum install -y oracle-j2sdk1.7
```
初始化数据库
```shell
# /usr/share/cmf/schema/scm_prepare_database.sh mysql cm root 123456
上面初始化数据库命令各参数如下：
# /usr/share/cmf/schema/scm_prepare_database.sh [postgresql|mysql|oracle] [database] [username] [password]
```
启动ClouderaManager Server
```shell
# systemctl start cloudera-scm-server
```
访问CM，验证安装
```shell
http://192.168.3.131:7180
初始用户名密码admin:admin
```
**4. 安装配置CDH**
======
安装前各服务器配置
```shell
# echo "vm.swappiness = 10" >> /etc/sysctl.conf
# sysctl -p
# echo never > /sys/kernel/mm/transparent_hugepage/defrag
# echo never > /sys/kernel/mm/transparent_hugepage/enabled
# echo -e 'echo never > /sys/kernel/mm/transparent_hugepage/defrag\necho never > /sys/kernel/mm/transparent_hugepage/enabled' >> /etc/rc.local

如上，修改内核参数，否则安装过程中会报警。
```
**登录web页面http://192.168.3.131:7180按需安装CDH服务，安装过程不详述，按步骤来即可。**
**5. 踩过的坑**
======
首次安装完成，启动kafka是会报错OOM，原因是Java Heap Size配置小了，回到CDH主页面，点击kafka，进入配置页面，修改 Java Heap Size of Broker为1G，然后保存，重启KAFKA，OK

这里就是个坑，安装的时候也没有提示哪里设置Java Heap Size。
**6. CM服务重启顺序**
======
```shell
# systemctl restart cloudera-scm-server
# systemctl restart cloudera-scm-agent（每个节点的agent都需要重启一下）
```



