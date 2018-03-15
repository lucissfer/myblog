---
title: MySQL+MHA安装部署
date: 2017-01-15
categories: 
 - Linux
 - MySQL

tags: 
 - MySQL
 - MHA

---

**1. 准备工作**
========
**软件包版本**
--------
> mysql-5.7.17.tar.gz
cmake-3.6.2.tar.gz
mha4mysql-manager-0.57.tar.gz
mha4mysql-node-0.57.tar.gz

**服务器明细**
--------
> kp-bt-101 Master
kp-bt-102   Candidate Master
kp-bt-103   Slave
kp-bt-13    MHA-manager

**2. 安装MySQL服务**
========
**解决依赖关系**
--------
```
# yum install -y gcc-c++ ncurses-devel openssh-clients
```
<!-- more -->

**配置ssh互信**
--------
```
在所有服务器均做如下配置
# ssh-keygen -t rsa
# ssh-copy-id -i /root/.ssh/id_rsa.pub "-p 16811 root@kp-bt-101"
# ssh-copy-id -i /root/.ssh/id_rsa.pub "-p 16812 root@kp-bt-102"
# ssh-copy-id -i /root/.ssh/id_rsa.pub "-p 16813 root@kp-bt-103"
# ssh-copy-id -i /root/.ssh/id_rsa.pub "-p 16813 root@kp-bt-13"
```
**安装cmake**
--------
```
# tar zxf cmake-3.6.2.tar.gz
# cd cmake-3.6.2/
# ./bootstrap
# gmake && gmake install
# cmake --version
```
**准备Boost库支持**
--------
```
# mkdir /usr/local/boost
# wget -o /usr/local/boost/boost_1_59_0.tar.gz http://ncu.dl.sourceforge.net/project/boost/boost/1.59.0/boost_1_59_0.tar.gz

boost1.63版本不支持MySQL5.7.17，编译时会报错。
```
**创建Mysql安装目录以及数据库文件存放的路径**
--------
```
# mkdir -p /home/mysql
# mkdir -p /home/mysql/data
```
**创建mysql用户以及对应用户组**
--------
```
# groupadd mysql
# useradd -r -g mysql mysql -s /sbin/nologin
```
**编译安装MySQL**
--------
```
# tar zxf mysql-5.7.17.tar.gz
# # cd mysql-5.7.17/
# cmake -DCMAKE_INSTALL_PREFIX=/home/mysql  -DMYSQL_UNIX_ADDR=/home/mysql/mysql.sock  -DDEFAULT_CHARSET=utf8  -DDEFAULT_COLLATION=utf8_general_ci  -DWITH_MYISAM_STORAGE_ENGINE=1  -DWITH_INNOBASE_STORAGE_ENGINE=1  -DWITH_MEMORY_STORAGE_ENGINE=1  -DWITH_READLINE=1  -DENABLED_LOCAL_INFILE=1  -DMYSQL_DATADIR=/home/mysql/data  -DMYSQL_USER=mysql  -DMYSQL_TCP_PORT=3306 -DWITH_BOOST=/usr/local/boost
# make && make install
```
**修改MySQL目录权限**
-------
```
# chown -R mysql.mysql /home/mysql/
```
**准备MySQL配置文件**
--------
```
# cp support-files/my-default.cnf /etc/my.cnf
kp-bt-101   Master
# vim /etc/my.cnf
[mysqld]
port            = 3306
basedir         = /home/mysql
datadir         = /home/mysql/data
tmpdir          = /home/mysql/tmp

log-error = /home/mysql/log/mysql_run.err
log-bin = /home/mysql/data/mysql-bin
binlog_format=mixed
expire_logs_days = 15
skip-name-resolve

#replication options
server-id = 1
relay-log=rep_relay_log
relay-log-index=rep_relay_log_index
skip-slave-start

kp-bt-102   Candidate Master
# vim /etc/my.cnf
[mysqld]
port            = 3306
socket          = /tmp/mysql.sock
basedir         = /home/mysql
datadir         = /home/mysql/data
tmpdir          = /home/mysql/tmp

log-error = /home/mysql/log/mysql_run.err
log-bin = /home/mysql/data/mysql-bin
binlog_format=mixed
expire_logs_days = 15
skip-name-resolve

#replication options
server-id = 2
relay-log=rep_relay_log
relay-log-index=rep_relay_log_index
skip-slave-start

kp-bt-103   Slave
# vim /etc/my.cnf
[mysqld]
port            = 3306
socket          = /tmp/mysql.sock
basedir         = /home/mysql
datadir         = /home/mysql/data
tmpdir          = /home/mysql/tmp

log-error = /home/mysql/log/mysql_run.err
log-bin = /home/mysql/data/mysql-bin
binlog_format=mixed
expire_logs_days = 15
skip-name-resolve

#replication options
server-id = 3
relay-log=rep_relay_log
relay-log-index=rep_relay_log_index
skip-slave-start
```
**初始化数据库、创建数据库系统表**
--------
```
# cd /home/mysql/
# bin/mysqld --initialize --user=mysql --basedir=/home/mysql/ --datadir=/home/mysql/data/
mysql初始化过程如果正常将不会出现任何提示，初始化过程中创建的默认密码输出到配置文件中指定的log_error文件中。
```
**设置环境变量**
--------
```
# vim /etc/profile.d/mysql.sh
export PATH=/home/mysql/bin:$PATH
```
**为MySQL提供服务脚本，并将MySQL服务加入开机启动**
--------
```
# cp support-files/mysql.server /etc/init.d/mysql
# chmod +x /etc/init.d/mysql
# chkconfig mysql on
```
**启动MySQL服务**
--------
```
# /etc/init.d/mysql start
```
**修改MySQL初始root密码**
```
# mysqladmin -uroot password 'password' -p'dh9>qmyaBIZe'
```
**配置iptables规则**
```
# iptables -I INPUT -p tcp --dport 3306 -s 192.168.1.0/24 -j ACCEPT
# service iptables save
所有MySQL节点都要配置iptables规则。
```
**3. 配置主从复制**
========
**创建数据库管理账号和复制账号及MHA监控账号**
--------
```
所有服务器均执行
mysql> grant all privileges on *.* to 'root'@'192.168.1.%' identified by 'nhE93d0qjPhkEcp3D';
mysql> grant replication slave,replication client,super on *.* to 'rep'@'192.168.1.%' identified by '2wsxzaq1';
mysql> grant all privileges on *.* to 'mha'@'192.168.1.%' identified by '4rfvxsw2';
mysql> flush privileges;
```
**配置主从复制**
--------
```
Master
查询Master状态
mysql> show master status;

Candidate Master
mysql> change master to master_host='192.168.1.101',master_port=3306,master_user='rep',master_password='2wsxzaq1',master_log_file='mysql-bin.000002',master_log_pos=1204;
mysql> start slave;

Slave
mysql> change master to master_host='192.168.1.101',master_port=3306,master_user='rep',master_password='2wsxzaq1',master_log_file='mysql-bin.000002',master_log_pos=1204;
mysql> start slave ;

```
**设置从库只读**
--------
```
mysql> set global read_only=1;
```
**检查主库、从库状态**
--------
```
Master
mysql> show master status \G

Slave
mysql> show slave tatus\G
检查Slave_IO_Running、Slave_SQL_Running是否为Yes，如果
Slave_IO_Running: Yes
Slave_SQL_Running: Yes
则说明主从复制正常。
```
**4. 安装配置MHA**
========
**安装MHA-manager**
--------
```
解决依赖关系
# yum install perl-DBD-MySQL perl-Config-Tiny perl-Log-Dispatch perl-Parallel-ForkManager  perl-Time-HiRes perl-ExtUtils-CBuilder perl-ExtUtils-MakeMaker -y
# wget http://www.cpan.org/authors/id/A/AN/ANDK/CPAN-2.14.tar.gz
# tar zxf CPAN-2.14.tar.gz 
# cd CPAN-2.14
# perl Makefile.PL
# make && make install

在mha-manager服务器上也需要安装mha-node
# tar zxf mha4mysql-node-0.57.tar.gz
# cd mha4mysql-node-0.57/
# perl Makefile.PL
# make && make install

安装mha-manager
# tar zxf mha4mysql-manager-0.57.tar.gz
# cd mha4mysql-manager-0.57/
# perl Makefile.PL
# make && make install

复制相关脚本到/usr/local/bin/
# cp samples/scripts/* /usr/local/bin/
```
**安装MHA-node**
--------
```
在所有MySQL节点安装mha-node
解决依赖关系
# yum install perl-DBD-MySQL perl-Config-Tiny perl-Log-Dispatch perl-Parallel-ForkManager  perl-Time-HiRes perl-ExtUtils-CBuilder perl-ExtUtils-MakeMaker -y
# wget http://www.cpan.org/authors/id/A/AN/ANDK/CPAN-2.14.tar.gz
# tar zxf CPAN-2.14.tar.gz 
# cd CPAN-2.14
# perl Makefile.PL
# make && make install

安装mha-node
# tar zxf mha4mysql-node-0.57.tar.gz
# cd mha4mysql-node-0.57/
# perl Makefile.PL
# make && make install
```
**配置MHA**
--------
```
创建MHA的工作目录，并且创建相关配置文件（在软件包解压后的目录里面有样例配置文件）
# mkdir -p /etc/masterha
# pwd
/root/soft/mysql/mha4mysql-manager-0.57
# cp samples/conf/app1.cnf /etc/masterha/
# vim /etc/masterha/app1.cnf
[server default]
manager_workdir=/var/log/masterha/app1.log              //设置manager的工作目录
manager_log=/var/log/masterha/app1/manager.log          //设置manager的日志
master_binlog_dir=/home/mysql/data                      //设置master 保存binlog的位置，以便MHA可以找到master的日志，我这里的也就是mysql的数据目录
master_ip_failover_script= /usr/local/bin/master_ip_failover    //设置自动failover时候的切换脚本
master_ip_online_change_script= /usr/local/bin/master_ip_online_change  //设置手动切换时候的切换脚本
user=mha                  设置监控用户mha
password=4rfvxsw2         //设置监控用户的密码
ping_interval=3         //设置监控主库，发送ping包的时间间隔，默认是3秒，尝试三次没有回应的时候自动进行railover
remote_workdir=/tmp     //设置远端mysql在发生切换时binlog的保存位置
repl_user=rep          //设置复制环境中的复制用户名
repl_password=2wsxzaq1    //设置复制用户的密码
report_script=/usr/local/bin/send_report    //设置发生切换后发送的报警的脚本
secondary_check_script= /usr/local/bin/masterha_secondary_check -s kp-bt-103 -s kp-bt-101            
shutdown_script=""      //设置故障发生后关闭故障主机脚本（该脚本的主要作用是关闭主机放在发生脑裂,这里没有使用）
ssh_user=root           //设置ssh的登录用户名

[server1]
hostname=kp-bt-101
ssh_port=16811
port=3306
candidate_master=1

[server2]
hostname=kp-bt-102
ssh_port=16812
port=3306
candidate_master=1   //设置为候选master，如果设置该参数以后，发生主从切换以后将会将此从库提升为主库，即使这个主库不是集群中事件最新的slave
check_repl_delay=0   //默认情况下如果一个slave落后master 100M的relay logs的话，MHA将不会选择该slave作为一个新的master，因为对于这个slave的恢复需要花费很长时间，通过设置check_repl_delay=0,MHA触发切换在选择一个新的master的时候将会忽略复制延时，这个参数对于设置了candidate_master=1的主机非常有用，因为这个候选主在切换的过程中一定是新的master

[server3]
hostname=kp-bt-103
ssh_port=16813
port=3306
no_master=1
```
**设置relay log的清除方式（在每个slave节点上）**
--------
```
mysql> set global relay_log_purge=0;
注意：

MHA在发生切换的过程中，从库的恢复过程中依赖于relay log的相关信息，所以这里要将relay log的自动清除设置为OFF，采用手动清除relay log的方式。在默认情况下，从服务器上的中继日志会在SQL线程执行完毕后被自动删除。但是在MHA环境中，这些中继日志在恢复其他从服务器时可能会被用到，因此需要禁用中继日志的自动删除功能。定期清除中继日志需要考虑到复制延时的问题。在ext3的文件系统下，删除大的文件需要一定的时间，会导致严重的复制延时。为了避免复制延时，需要暂时为中继日志创建硬链接，因为在linux系统中通过硬链接删除大文件速度会很快。（在mysql数据库中，删除大表时，通常也采用建立硬链接的方式）

MHA节点中包含了pure_relay_logs命令工具，它可以为中继日志创建硬链接，执行SET GLOBAL relay_log_purge=1,等待几秒钟以便SQL线程切换到新的中继日志，再执行SET GLOBAL relay_log_purge=0。

pure_relay_logs脚本参数如下所示：

--user mysql                      用户名
--password mysql                  密码
--port                            端口号
--workdir                         指定创建relay log的硬链接的位置，默认是/var/tmp，由于系统不同分区创建硬链接文件会失败，故需要执行硬链接具体位置，成功执行脚本后，硬链接的中继日志文件被删除
--disable_relay_log_purge         默认情况下，如果relay_log_purge=1，脚本会什么都不清理，自动退出，通过设定这个参数，当relay_log_purge=1的情况下会将relay_log_purge设置为0。清理relay log之后，最后将参数设置为OFF。
```
**设置定期清理relay脚本(slave)**
--------
```
# vim purge_relay_log.sh

#!/bin/bash
user=root
passwd=nhE93d0qjPhkEcp3D
port=3306
log_dir='/home/mha/log/'
work_dir='/home/mysql/data/'
purge='/usr/local/bin/purge_relay_logs'

if [ ! -d $log_dir ]
then
   mkdir $log_dir -p
fi

$purge --user=$user --password=$passwd --disable_relay_log_purge --port=$port --workdir=$work_dir >> $log_dir/purge_relay_logs.log 2>&1

# chmod +x purge_relay_log.sh
将此脚本加入计划任务
# crontab -l
0 4 * * * /bin/bash /home/scripts/purge_relay_log.sh

手动执行日志清除命令测试
# /usr/local/bin/purge_relay_logs --user=root --password=nhE93d0qjPhkEcp3D --port=3306 -disable_relay_log_purge --workdir=/home/mysql/data/
2017-01-12 04:05:58: purge_relay_logs script started.
 Found relay_log.info: /home/mysql/data/relay-log.info
 Opening /home/mysql/data/rep_relay_log.000001 ..
 Opening /home/mysql/data/rep_relay_log.000002 ..
 Executing SET GLOBAL relay_log_purge=1; FLUSH LOGS; sleeping a few seconds so that SQL thread can delete older relay log files (if it keeps up); SET GLOBAL relay_log_purge=0; .. ok.
2017-01-12 04:06:01: All relay log purging operations succeeded.

如果出现错误提示：
2017-01-12 03:47:16: purge_relay_logs script started.
DBI connect(';host=127.0.0.1;port=3306','root',...) failed: Host '127.0.0.1' is not allowed to connect to this MySQL server at /usr/local/bin/purge_relay_logs line 185
则是因为，在MySQL5.7中，默认没有创建root@127.0.0.1用户，此时我们需要手动创建用户
mysql> grant all privileges on *.* to 'root'@'127.0.0.1' identified by 'nhE93d0qjPhkEcp3D';
```
**在MHA-master上检查ssh配置**
--------
```
检查MHA Manger到所有MHA Node的SSH连接状态：
# masterha_check_ssh --conf=/etc/masterha/app1.cnf 
Thu Jan 12 04:09:23 2017 - [warning] Global configuration file /etc/masterha_default.cnf not found. Skipping.
Thu Jan 12 04:09:23 2017 - [info] Reading application default configuration from /etc/masterha/app1.cnf..
Thu Jan 12 04:09:23 2017 - [info] Reading server configuration from /etc/masterha/app1.cnf..
Thu Jan 12 04:09:23 2017 - [info] Starting SSH connection tests..
Thu Jan 12 04:09:23 2017 - [debug] 
Thu Jan 12 04:09:23 2017 - [debug]  Connecting via SSH from root@kp-bt-101(192.168.1.101:16811) to root@kp-bt-102(192.168.1.102:16812)..
Thu Jan 12 04:09:23 2017 - [debug]   ok.
Thu Jan 12 04:09:23 2017 - [debug]  Connecting via SSH from root@kp-bt-101(192.168.1.101:16811) to root@kp-bt-103(192.168.1.103:16813)..
Thu Jan 12 04:09:23 2017 - [debug]   ok.
Thu Jan 12 04:09:24 2017 - [debug] 
Thu Jan 12 04:09:23 2017 - [debug]  Connecting via SSH from root@kp-bt-102(192.168.1.102:16812) to root@kp-bt-101(192.168.1.101:16811)..
Thu Jan 12 04:09:24 2017 - [debug]   ok.
Thu Jan 12 04:09:24 2017 - [debug]  Connecting via SSH from root@kp-bt-102(192.168.1.102:16812) to root@kp-bt-103(192.168.1.103:16813)..
Thu Jan 12 04:09:24 2017 - [debug]   ok.
Thu Jan 12 04:09:24 2017 - [debug] 
Thu Jan 12 04:09:24 2017 - [debug]  Connecting via SSH from root@kp-bt-103(192.168.1.103:16813) to root@kp-bt-101(192.168.1.101:16811)..
Thu Jan 12 04:09:24 2017 - [debug]   ok.
Thu Jan 12 04:09:24 2017 - [debug]  Connecting via SSH from root@kp-bt-103(192.168.1.103:16813) to root@kp-bt-102(192.168.1.102:16812)..
Thu Jan 12 04:09:24 2017 - [debug]   ok.
Thu Jan 12 04:09:24 2017 - [info] All SSH connection tests passed successfully.
所有节点正常。
```
**使用MHA-manager检查复制集群状态**
-------
```
# masterha_check_ssh --conf=/etc/masterha/app1.cnf 
Thu Jan 12 04:09:23 2017 - [warning] Global configuration file /etc/masterha_default.cnf not found. Skipping.
Thu Jan 12 04:09:23 2017 - [info] Reading application default configuration from /etc/masterha/app1.cnf..
Thu Jan 12 04:09:23 2017 - [info] Reading server configuration from /etc/masterha/app1.cnf..
Thu Jan 12 04:09:23 2017 - [info] Starting SSH connection tests..
Thu Jan 12 04:09:23 2017 - [debug] 
Thu Jan 12 04:09:23 2017 - [debug]  Connecting via SSH from root@kp-bt-101(192.168.1.101:16811) to root@kp-bt-102(192.168.1.102:16812)..
Thu Jan 12 04:09:23 2017 - [debug]   ok.
Thu Jan 12 04:09:23 2017 - [debug]  Connecting via SSH from root@kp-bt-101(192.168.1.101:16811) to root@kp-bt-103(192.168.1.103:16813)..
Thu Jan 12 04:09:23 2017 - [debug]   ok.
Thu Jan 12 04:09:24 2017 - [debug] 
Thu Jan 12 04:09:23 2017 - [debug]  Connecting via SSH from root@kp-bt-102(192.168.1.102:16812) to root@kp-bt-101(192.168.1.101:16811)..
Thu Jan 12 04:09:24 2017 - [debug]   ok.
Thu Jan 12 04:09:24 2017 - [debug]  Connecting via SSH from root@kp-bt-102(192.168.1.102:16812) to root@kp-bt-103(192.168.1.103:16813)..
Thu Jan 12 04:09:24 2017 - [debug]   ok.
Thu Jan 12 04:09:24 2017 - [debug] 
Thu Jan 12 04:09:24 2017 - [debug]  Connecting via SSH from root@kp-bt-103(192.168.1.103:16813) to root@kp-bt-101(192.168.1.101:16811)..
Thu Jan 12 04:09:24 2017 - [debug]   ok.
Thu Jan 12 04:09:24 2017 - [debug]  Connecting via SSH from root@kp-bt-103(192.168.1.103:16813) to root@kp-bt-102(192.168.1.102:16812)..
Thu Jan 12 04:09:24 2017 - [debug]   ok.
Thu Jan 12 04:09:24 2017 - [info] All SSH connection tests passed successfully.
[root@kp-bt-13 bin]# masterha_check_repl --conf=/etc/masterha/app1.cnf
Thu Jan 12 04:10:17 2017 - [warning] Global configuration file /etc/masterha_default.cnf not found. Skipping.
Thu Jan 12 04:10:17 2017 - [info] Reading application default configuration from /etc/masterha/app1.cnf..
Thu Jan 12 04:10:17 2017 - [info] Reading server configuration from /etc/masterha/app1.cnf..
Thu Jan 12 04:10:17 2017 - [info] MHA::MasterMonitor version 0.57.
Creating directory /var/log/masterha/app1.log.. done.
Thu Jan 12 04:10:17 2017 - [error][/usr/local/share/perl5/MHA/ServerManager.pm, ln193] There is no alive slave. We can't do failover
Thu Jan 12 04:10:17 2017 - [error][/usr/local/share/perl5/MHA/MasterMonitor.pm, ln427] Error happened on checking configurations.  at /usr/local/share/perl5/MHA/MasterMonitor.pm line 329
Thu Jan 12 04:10:17 2017 - [error][/usr/local/share/perl5/MHA/MasterMonitor.pm, ln525] Error happened on monitoring servers.
Thu Jan 12 04:10:17 2017 - [info] Got exit code 1 (Not master dead).

MySQL Replication Health is NOT OK!
```
**检查复制状态is NOT OK的集中常见错误及解决办法**
--------
```
报错提示：
[error][/usr/local/share/perl5/MHA/MasterMonitor.pm, ln427] Error happened on checking configurations.  at /usr/local/share/perl5/MHA/MasterMonitor.pm line 329
解决办法：
在所有节点设置
# ln -s /home/mysql/bin/mysqlbinlog /usr/local/bin/mysqlbinlog
# ln -s /home/mysql/bin/mysql /usr/local/bin/mysql

报错提示：
mysqlbinlog: [ERROR] unknown variable 'default-character-set=utf8'
mysqlbinlog version command failed with rc 7:0, please verify PATH, LD_LIBRARY_PATH, and client options
 at /usr/local/bin/apply_diff_relay_logs line 493
产生这个问题的原因是因为我在my.cnf中的client选项组中添加了default-character-set=utf8
解决办法：
在所有MySQL节点上的my.cnf文件client配置段注释掉default-character-set =utf8
# default-character-set =utf8
无需重启MySQL服务，因为使用mysqlbinlog工具查看二进制日志时会重新读取的mysql的配置文件my.cnf，而不是服务器已经加载进内存的配置文件。

报错提示：
Execution of /usr/local/bin/master_ip_failover aborted due to compilation errors.
Thu Jan 12 13:26:30 2017 - [error][/usr/local/share/perl5/MHA/MasterMonitor.pm, ln229]  Failed to get master_ip_failover_script status with return code 255:0.
这是因为我们还没有配置master_ip_failover文件，先在配置文件中注释掉master_ip_failover_script= /usr/local/bin/master_ip_failover就可以了。
# master_ip_failover_script= /usr/local/bin/master_ip_failover
```
**再次运行masterha_check_repl脚本检查集群复制状态**
--------
```
# masterha_check_repl --conf=/etc/masterha/app1.cnf
Thu Jan 12 14:29:38 2017 - [warning] Global configuration file /etc/masterha_default.cnf not found. Skipping.
Thu Jan 12 14:29:38 2017 - [info] Reading application default configuration from /etc/masterha/app1.cnf..
Thu Jan 12 14:29:38 2017 - [info] Reading server configuration from /etc/masterha/app1.cnf..
Thu Jan 12 14:29:38 2017 - [info] MHA::MasterMonitor version 0.57.
Thu Jan 12 14:29:38 2017 - [info] GTID failover mode = 0
Thu Jan 12 14:29:38 2017 - [info] Dead Servers:
Thu Jan 12 14:29:38 2017 - [info] Alive Servers:
Thu Jan 12 14:29:38 2017 - [info]   kp-bt-101(192.168.1.101:3306)
Thu Jan 12 14:29:38 2017 - [info]   kp-bt-102(192.168.1.102:3306)
Thu Jan 12 14:29:38 2017 - [info]   kp-bt-103(192.168.1.103:3306)
Thu Jan 12 14:29:38 2017 - [info] Alive Slaves:
Thu Jan 12 14:29:38 2017 - [info]   kp-bt-102(192.168.1.102:3306)  Version=5.7.17-log (oldest major version between slaves) log-bin:enabled
Thu Jan 12 14:29:38 2017 - [info]     Replicating from 192.168.1.101(192.168.1.101:3306)
Thu Jan 12 14:29:38 2017 - [info]     Primary candidate for the new Master (candidate_master is set)
Thu Jan 12 14:29:38 2017 - [info]   kp-bt-103(192.168.1.103:3306)  Version=5.7.17-log (oldest major version between slaves) log-bin:enabled
Thu Jan 12 14:29:38 2017 - [info]     Replicating from 192.168.1.101(192.168.1.101:3306)
Thu Jan 12 14:29:38 2017 - [info]     Not candidate for the new Master (no_master is set)
Thu Jan 12 14:29:38 2017 - [info] Current Alive Master: kp-bt-101(192.168.1.101:3306)
Thu Jan 12 14:29:38 2017 - [info] Checking slave configurations..
Thu Jan 12 14:29:38 2017 - [info] Checking replication filtering settings..
Thu Jan 12 14:29:38 2017 - [info]  binlog_do_db= , binlog_ignore_db= 
Thu Jan 12 14:29:38 2017 - [info]  Replication filtering check ok.
Thu Jan 12 14:29:38 2017 - [info] GTID (with auto-pos) is not supported
Thu Jan 12 14:29:38 2017 - [info] Starting SSH connection tests..
Thu Jan 12 14:29:40 2017 - [info] All SSH connection tests passed successfully.
Thu Jan 12 14:29:40 2017 - [info] Checking MHA Node version..
Thu Jan 12 14:29:40 2017 - [info]  Version check ok.
Thu Jan 12 14:29:40 2017 - [info] Checking SSH publickey authentication settings on the current master..
Thu Jan 12 14:29:40 2017 - [info] HealthCheck: SSH to kp-bt-101 is reachable.
Thu Jan 12 14:29:40 2017 - [info] Master MHA Node version is 0.57.
Thu Jan 12 14:29:40 2017 - [info] Checking recovery script configurations on kp-bt-101(192.168.1.101:3306)..
Thu Jan 12 14:29:40 2017 - [info]   Executing command: save_binary_logs --command=test --start_pos=4 --binlog_dir=/home/mysql/data --output_file=/tmp/save_binary_logs_test --manager_version=0.57 --start_file=mysql-bin.000002 
Thu Jan 12 14:29:40 2017 - [info]   Connecting to root@192.168.1.101(kp-bt-101:16811).. 
  Creating /tmp if not exists..    ok.
  Checking output directory is accessible or not..
   ok.
  Binlog found at /home/mysql/data, up to mysql-bin.000002
Thu Jan 12 14:29:41 2017 - [info] Binlog setting check done.
Thu Jan 12 14:29:41 2017 - [info] Checking SSH publickey authentication and checking recovery script configurations on all alive slave servers..
Thu Jan 12 14:29:41 2017 - [info]   Executing command : apply_diff_relay_logs --command=test --slave_user='mha' --slave_host=kp-bt-102 --slave_ip=192.168.1.102 --slave_port=3306 --workdir=/tmp --target_version=5.7.17-log --manager_version=0.57 --relay_log_info=/home/mysql/data/relay-log.info  --relay_dir=/home/mysql/data/  --slave_pass=xxx
Thu Jan 12 14:29:41 2017 - [info]   Connecting to root@192.168.1.102(kp-bt-102:16812).. 
  Checking slave recovery environment settings..
    Opening /home/mysql/data/relay-log.info ... ok.
    Relay log found at /home/mysql/data, up to rep_relay_log.000003
    Temporary relay log file is /home/mysql/data/rep_relay_log.000003
    Testing mysql connection and privileges..mysql: [Warning] Using a password on the command line interface can be insecure.
 done.
    Testing mysqlbinlog output.. done.
    Cleaning up test file(s).. done.
Thu Jan 12 14:29:41 2017 - [info]   Executing command : apply_diff_relay_logs --command=test --slave_user='mha' --slave_host=kp-bt-103 --slave_ip=192.168.1.103 --slave_port=3306 --workdir=/tmp --target_version=5.7.17-log --manager_version=0.57 --relay_log_info=/home/mysql/data/relay-log.info  --relay_dir=/home/mysql/data/  --slave_pass=xxx
Thu Jan 12 14:29:41 2017 - [info]   Connecting to root@192.168.1.103(kp-bt-103:16813).. 
  Checking slave recovery environment settings..
    Opening /home/mysql/data/relay-log.info ... ok.
    Relay log found at /home/mysql/data, up to rep_relay_log.000003
    Temporary relay log file is /home/mysql/data/rep_relay_log.000003
    Testing mysql connection and privileges..mysql: [Warning] Using a password on the command line interface can be insecure.
 done.
    Testing mysqlbinlog output.. done.
    Cleaning up test file(s).. done.
Thu Jan 12 14:29:41 2017 - [info] Slaves settings check done.
Thu Jan 12 14:29:41 2017 - [info] 
kp-bt-101(192.168.1.101:3306) (current master)
 +--kp-bt-102(192.168.1.102:3306)
 +--kp-bt-103(192.168.1.103:3306)

Thu Jan 12 14:29:41 2017 - [info] Checking replication health on kp-bt-102..
Thu Jan 12 14:29:41 2017 - [info]  ok.
Thu Jan 12 14:29:41 2017 - [info] Checking replication health on kp-bt-103..
Thu Jan 12 14:29:41 2017 - [info]  ok.
Thu Jan 12 14:29:41 2017 - [warning] master_ip_failover_script is not defined.
Thu Jan 12 14:29:41 2017 - [warning] shutdown_script is not defined.
Thu Jan 12 14:29:41 2017 - [info] Got exit code 0 (Not master dead).

MySQL Replication Health is OK.
```
**配置自动故障vip切换脚本**
--------
```
#!/usr/bin/env perl
  
use strict;
use warnings FATAL => 'all';
  
use Getopt::Long;
  
my (
    $command,          $ssh_user,        $orig_master_host, $orig_master_ip,
    $orig_master_port, $new_master_host, $new_master_ip,    $new_master_port
);
  
my $vip = '192.168.1.110/16';  # Virtual IP
my $interface = 'em2';          #bind to interface
my $key = "1";
my $ssh_start_vip = "/sbin/ifconfig $interface:$key $vip";
my $ssh_stop_vip = "/sbin/ifconfig $interface:$key down";
$ssh_user = "root";
  
GetOptions(
    'command=s'          => \$command,
    'ssh_user=s'         => \$ssh_user,
    'orig_master_host=s' => \$orig_master_host,
    'orig_master_ip=s'   => \$orig_master_ip,
    'orig_master_port=i' => \$orig_master_port,
    'new_master_host=s'  => \$new_master_host,
    'new_master_ip=s'    => \$new_master_ip,
    'new_master_port=i'  => \$new_master_port,
);
  
exit &main();
  
sub main {
  
    print "\n\nIN SCRIPT TEST====$ssh_stop_vip==$ssh_start_vip===\n\n";
  
    if ( $command eq "stop" || $command eq "stopssh" ) {
  
        # $orig_master_host, $orig_master_ip, $orig_master_port are passed.
        # If you manage master ip address at global catalog database,
        # invalidate orig_master_ip here.
        my $exit_code = 1;
  
        #eval {
        #    print "Disabling the VIP on old master: $orig_master_host \n";
        #    &stop_vip();
        #    $exit_code = 0;
        #};
  
  
        eval {
                print "Disabling the VIP on old master: $orig_master_host \n";
                #my $ping=`ping -c 1 10.0.0.13 | grep "packet loss" | awk -F',' '{print $3}' | awk '{print $1}'`;
                #if ( $ping le "90.0%" && $ping gt "0.0%" ){
                #$exit_code = 0;
                #}
                #else {
  
                &stop_vip();
  
                # updating global catalog, etc
                $exit_code = 0;
  
                #}
        };
  
  
        if ($@) {
            warn "Got Error: $@\n";
            exit $exit_code;
        }
        exit $exit_code;
    }
    elsif ( $command eq "start" ) {
  
        # all arguments are passed.
        # If you manage master ip address at global catalog database,
        # activate new_master_ip here.
        # You can also grant write access (create user, set read_only=0, etc) here.
        my $exit_code = 10;
        eval {
            print "Enabling the VIP - $vip on the new master - $new_master_host \n";
            &start_vip();
            $exit_code = 0;
        };
        if ($@) {
            warn $@;
            exit $exit_code;
        }
        exit $exit_code;
    }
    elsif ( $command eq "status" ) {
        print "Checking the Status of the script.. OK \n";
        `ssh $ssh_user\@$orig_master_ip \" $ssh_start_vip \"`;
        exit 0;
    }
    else {
        &usage();
        exit 1;
    }
}
  
# A simple system call that enable the VIP on the new master
sub start_vip() {
    `ssh $ssh_user\@$new_master_host \" $ssh_start_vip \"`;
}
  
# A simple system call that disable the VIP on the old_master
sub stop_vip() {
    `ssh $ssh_user\@$orig_master_host \" $ssh_stop_vip \"`;
}
  
sub usage {
    print
    "Usage: master_ip_failover --command=start|stop|stopssh|status --orig_master_host=host --orig_master_ip=ip --orig_master_port=port --new_master_host=host --new_master_ip=ip --new_master_port=port\n";
}
```
**配置手动故障vip切换脚本**
--------
```
#!/usr/bin/env perl
#  Copyright (C) 2011 DeNA Co.,Ltd.
#
#  This program is free software; you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published by
#  the Free Software Foundation; either version 2 of the License, or
#  (at your option) any later version.
#
#  This program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.
#
#  You should have received a copy of the GNU General Public License
#   along with this program; if not, write to the Free Software
#  Foundation, Inc.,
#  51 Franklin Street, Fifth Floor, Boston, MA  02110-1301  USA
## Note: This is a sample script and is not complete. Modify the script based on your environment.
use strict;
use warnings FATAL => 'all';
use Getopt::Long;
use MHA::DBHelper;
use MHA::NodeUtil;
use Time::HiRes qw( sleep gettimeofday tv_interval );
use Data::Dumper;
my $_tstart;
my $_running_interval = 0.1;
my (
  $command,          $orig_master_host, $orig_master_ip,
  $orig_master_port, $orig_master_user, $orig_master_ssh_user,
  $new_master_host,  $new_master_ip,    $new_master_port,
  $new_master_user,  $new_master_ssh_user, $orig_master_is_new_slave,
  $orig_master_password, $new_master_password,
);
my $vip = '192.168.1.110';      ###Virtual IP
my $interface = 'em2';         ###interface
my $key = "1";
my $ssh_start_vip = "/sbin/ifconfig $interface:$key $vip/16";
my $flush_arp = "/sbin/arping -I $interface -c 2 -s $vip";
my $ssh_stop_vip = "/sbin/ifconfig $interface:$key down";
my $ssh_user = "root";
GetOptions(
  'command=s'              => \$command,
  'ssh_user=s'             => \$ssh_user,
  'orig_master_host=s'     => \$orig_master_host,
  'orig_master_ip=s'       => \$orig_master_ip,
  'orig_master_port=i'     => \$orig_master_port,
  'orig_master_user=s'     => \$orig_master_user,
  'orig_master_password=s' => \$orig_master_password,
  'new_master_host=s'      => \$new_master_host,
  'new_master_ip=s'        => \$new_master_ip,
  'new_master_port=i'      => \$new_master_port,
  'new_master_user=s'      => \$new_master_user,
  'new_master_password=s'  => \$new_master_password,
  'orig_master_ssh_user=s'   => \$orig_master_ssh_user,
  'new_master_ssh_user=s'    => \$new_master_ssh_user,
  'orig_master_is_new_slave' => \$orig_master_is_new_slave,
);
exit &main();
sub current_time_us {
  my ( $sec, $microsec ) = gettimeofday();
  my $curdate = localtime($sec);
  return $curdate . " " . sprintf( "%06d", $microsec );
}
sub sleep_until {
  my $elapsed = tv_interval($_tstart);
  if ( $_running_interval > $elapsed ) {
    sleep( $_running_interval - $elapsed );
  }
}
sub get_threads_util {
  my $dbh                    = shift;
  my $my_connection_id       = shift;
  my $running_time_threshold = shift;
  my $type                   = shift;
  $running_time_threshold = 0 unless ($running_time_threshold);
  $type                   = 0 unless ($type);
  my @threads;
  my $sth = $dbh->prepare("SHOW PROCESSLIST");
  $sth->execute();
  while ( my $ref = $sth->fetchrow_hashref() ) {
    my $id         = $ref->{Id};
    my $user       = $ref->{User};
    my $host       = $ref->{Host};
    my $command    = $ref->{Command};
    my $state      = $ref->{State};
    my $query_time = $ref->{Time};
    my $info       = $ref->{Info};
    $info =~ s/^\s*(.*?)\s*$/$1/ if defined($info);
    next if ( $my_connection_id == $id );
    next if ( defined($query_time) && $query_time < $running_time_threshold );
    next if ( defined($command)    && $command eq "Binlog Dump" );
    next if ( defined($user)       && $user eq "system user" );
    next
      if ( defined($command)
      && $command eq "Sleep"
      && defined($query_time)
      && $query_time >= 1 );
    if ( $type >= 1 ) {
      next if ( defined($command) && $command eq "Sleep" );
      next if ( defined($command) && $command eq "Connect" );
    }
    if ( $type >= 2 ) {
      next if ( defined($info) && $info =~ m/^select/i );
      next if ( defined($info) && $info =~ m/^show/i );
    }
    push @threads, $ref;
  }
  return @threads;
}
sub main {
  if ( $command eq "stop" ) {
    ## Gracefully killing connections on the current master
    # 1. Set read_only= 1 on the new master
    # 2. DROP USER so that no app user can establish new connections
    # 3. Set read_only= 1 on the current master
    # 4. Kill current queries
    # * Any database access failure will result in script die.
    my $exit_code = 1;
    eval {
      ## Setting read_only=1 on the new master (to avoid accident)
      my $new_master_handler = new MHA::DBHelper();
      # args: hostname, port, user, password, raise_error(die_on_error)_or_not
      $new_master_handler->connect( $new_master_ip, $new_master_port,
        $new_master_user, $new_master_password, 1 );
      print current_time_us() . " Set read_only on the new master.. ";
      $new_master_handler->enable_read_only();
      if ( $new_master_handler->is_read_only() ) {
        print "ok.\n";
      }
      else {
        die "Failed!\n";
      }
      $new_master_handler->disconnect();
      # Connecting to the orig master, die if any database error happens
      my $orig_master_handler = new MHA::DBHelper();
      $orig_master_handler->connect( $orig_master_ip, $orig_master_port,
        $orig_master_user, $orig_master_password, 1 );
      ## Drop application user so that nobody can connect. Disabling per-session binlog beforehand
      #$orig_master_handler->disable_log_bin_local();
      #print current_time_us() . " Drpping app user on the orig master..\n";
      #FIXME_xxx_drop_app_user($orig_master_handler);
      ## Waiting for N * 100 milliseconds so that current connections can exit
      my $time_until_read_only = 15;
      $_tstart = [gettimeofday];
      my @threads = get_threads_util( $orig_master_handler->{dbh},
        $orig_master_handler->{connection_id} );
      while ( $time_until_read_only > 0 && $#threads >= 0 ) {
        if ( $time_until_read_only % 5 == 0 ) {
          printf
"%s Waiting all running %d threads are disconnected.. (max %d milliseconds)\n",
            current_time_us(), $#threads + 1, $time_until_read_only * 100;
          if ( $#threads < 5 ) {
            print Data::Dumper->new( [$_] )->Indent(0)->Terse(1)->Dump . "\n"
              foreach (@threads);
          }
        }
        sleep_until();
        $_tstart = [gettimeofday];
        $time_until_read_only--;
        @threads = get_threads_util( $orig_master_handler->{dbh},
          $orig_master_handler->{connection_id} );
      }
      ## Setting read_only=1 on the current master so that nobody(except SUPER) can write
      print current_time_us() . " Set read_only=1 on the orig master.. ";
      $orig_master_handler->enable_read_only();
      if ( $orig_master_handler->is_read_only() ) {
        print "ok.\n";
      }
      else {
        die "Failed!\n";
      }
      ## Waiting for M * 100 milliseconds so that current update queries can complete
      my $time_until_kill_threads = 5;
      @threads = get_threads_util( $orig_master_handler->{dbh},
        $orig_master_handler->{connection_id} );
      while ( $time_until_kill_threads > 0 && $#threads >= 0 ) {
        if ( $time_until_kill_threads % 5 == 0 ) {
          printf
"%s Waiting all running %d queries are disconnected.. (max %d milliseconds)\n",
            current_time_us(), $#threads + 1, $time_until_kill_threads * 100;
          if ( $#threads < 5 ) {
            print Data::Dumper->new( [$_] )->Indent(0)->Terse(1)->Dump . "\n"
              foreach (@threads);
          }
        }
        sleep_until();
        $_tstart = [gettimeofday];
        $time_until_kill_threads--;
        @threads = get_threads_util( $orig_master_handler->{dbh},
          $orig_master_handler->{connection_id} );
                &stop_vip();
      ## Terminating all threads
      print current_time_us() . " Killing all application threads..\n";
      $orig_master_handler->kill_threads(@threads) if ( $#threads >= 0 );
      print current_time_us() . " done.\n";
      #$orig_master_handler->enable_log_bin_local();
      $orig_master_handler->disconnect();
      ## After finishing the script, MHA executes FLUSH TABLES WITH READ LOCK
      $exit_code = 0;
    };
    if ($@) {
      warn "Got Error: $@\n";
      exit $exit_code;
    }
    exit $exit_code;
  }
  elsif ( $command eq "start" ) {
    ## Activating master ip on the new master
    # 1. Create app user with write privileges
    # 2. Moving backup script if needed
    # 3. Register new master's ip to the catalog database
# If exit code is 0 or 10, MHA does not abort
    my $exit_code = 10;
    eval {
      my $new_master_handler = new MHA::DBHelper();
      # args: hostname, port, user, password, raise_error_or_not
      $new_master_handler->connect( $new_master_ip, $new_master_port,
        $new_master_user, $new_master_password, 1 );
      ## Set read_only=0 on the new master
      #$new_master_handler->disable_log_bin_local();
      print current_time_us() . " Set read_only=0 on the new master.\n";
      $new_master_handler->disable_read_only();
      ## Creating an app user on the new master
      #print current_time_us() . " Creating app user on the new master..\n";
      #FIXME_xxx_create_app_user($new_master_handler);
      #$new_master_handler->enable_log_bin_local();
      $new_master_handler->disconnect();
      ## Update master ip on the catalog database, etc
                print "Enabling the VIP - $vip on the new master - $new_master_host \n";
                &start_vip();
                &flush_arp();
                $exit_code = 0;
    };
    if ($@) {
      warn "Got Error: $@\n";
      exit $exit_code;
    }
    exit $exit_code;
  }
    exit 0;
  }
  else {
    &usage();
    exit 1;
  }
}
# A simple system call that enable the VIP on the new master
sub start_vip() {
    `ssh $ssh_user\@$new_master_host \" $ssh_start_vip \"`;
}
# A simple system call that disable the VIP on the old_master
sub stop_vip() {
    `ssh $ssh_user\@$orig_master_host \" $ssh_stop_vip \"`;
}
#flush arp
sub flush_arp() {
    `ssh $ssh_user\@$new_master_host \" $flush_arp \"`;
}
sub usage {
  print
"Usage: master_ip_online_change --command=start|stop|status --orig_master_host=host --orig_master_ip=ip --orig_master_port=port --new_master_host=host --new_master_ip=ip --new_master_port=port\n";
  die;
}
```
**检查集群状态**
```
# masterha_check_repl --conf=/etc/masterha/app1.cnf
# masterha_check_ssh --conf=/etc/masterha/app1.cnf
```
**启动和关闭MHA-manager**
--------
```
启动
# nohup masterha_manager --conf=/etc/masterha/app1.cnf > /etc/masterha//mha_manager.log < /dev/null 2>&1 &

关闭
masterha_stop --conf=/etc/masterha/app1.cnf
```
**检查MHA-manager状态**
--------
```
# masterha_check_status --conf=/etc/masterha/app1.cnf
app1 (pid:50523) is running(0:PING_OK), master:kp-bt-101
```
