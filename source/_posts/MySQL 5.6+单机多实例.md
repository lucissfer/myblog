---
title: MySQL 5.6单机多实例配置
date: 2016-09-28
categories: 
 - Linux
 - MySQL

tags: 
 - MySQL5.6
 - 单机多实例

---

> **前言：**因为所在公司是小公司，经费有限，所以线下测试服务器数量不足。一直以来，开发与测试都是公用一套MySQL环境，然而由于开发与数据对于MySQL数据的需求不完全一致，导致日常工作中经常出现数据干扰，影响工作。因此，为了提高工作效率，决定将开发与测试的MySQL环境分离，然而当前手上只有一台服务器，条件有限，所以只能部署MySQL单机多实例。
MySQL服务器环境：Centos 7.1 + MySQL 5.6.24

1. 创建数据目录
---------

```shell
# mkdir -p /data/mysql /data/mysql2
```

2. 初始化数据库
---------
```shell
# scripts/mysql_install_db --basedir=/usr/local/mysql --datadir=/data/mysql --user=mysql
# scripts/mysql_install_db --basedir=/usr/local/mysql --datadir=/data/mysql2 --user=mysql
```
3. 生成MySQL多实例配置文件
---------
```shell
# mysqld_multi --example > /data/multi.cnf
# chown mysql.mysql multi.cnf
```
此处，我们采用的MySQL的官方解决方案mysqld_multi来实现。

<!-- more -->

4. 配置MySQL多实例配置文件
---------
```shell
# vim multi.cnf

[mysqld_multi]
mysqld     = /usr/local/mysql/bin/mysqld_safe
mysqladmin = /usr/local/mysql/bin/mysqladmin
user       = multi_admin
password   = password
#这个用户应该有关机权限，然后没有其他的权限。建议创建一个通用的multi_admin用户控制其它的MySQL用户，例如
#GRANT SHUTDOWN ON *.* TO multi_admin@localhost IDENTIFIED BY 'password'

[mysqld1]
character_set_server =utf8
socket     = /tmp/mysql.sock1
port       = 3306
pid-file   = /data/mysql/hostname.pid1
datadir    = /data/mysql
log-error = /data/mysql/log/mysql_run.err
#language   = /usr/local/mysql/share/mysql/english
#user       = mysql

slow_query_log=1
long_query_time=2
max_connections = 3000
log_bin_trust_function_creators=1


[mysqld2]
character_set_server =utf8
socket     = /tmp/mysql.sock2
port       = 3307
pid-file   = /data/mysql2/hostname.pid2
datadir    = /data/mysql2
log-error = /data/mysql2/log/mysql_run.err
#language   = /usr/local/mysql/share/mysql/english
#user       = mysql

slow_query_log=1
long_query_time=2
max_connections = 3000
#log_bin_trust_function_creators=1

```
5. 启动、关闭MySQL数据库多实例
----------
```shell
# mysqld_multi --defaults-file=/data/multi.cnf start 1,2
启动时需指定multi.cnf配置文件。

如果只需要启动实例mysqld1，仅需
# mysqld_multi --defaults-file=/data/multi.cnf start 1

关闭多个实例
# /usr/local/mysql/bin/mysqld_multi --defaults-extra-file=/data/multi.cnf --user=mysql_admin --password=password stop 1,2

关闭单个实例
# /usr/local/mysql/bin/mysqld_multi --defaults-extra-file=/data/multi.cnf --user=mysql_admin --password=password stop 1

```

6. 配置管理脚本
---------
为了管理方便，写一个简单的管理脚本。
```shell
# vim /etc/init.d/mysql_multi

#!/bin/bash
#
basedir=/usr/local/mysql
bindir=/usr/local/mysql/bin
conf=/data/multi.cnf
user=multi_admin
password=password

export PATH=$bindir:/$PATH
if test -x $bindir/mysqld_multi
then
  mysqld_multi="$bindir/mysqld_multi";
else
  echo "Can't execute $bindir/mysqld_multi from dir $basedir";
  exit;
fi
case "$1" in
    'start' )
        "$mysqld_multi" --defaults-extra-file=$conf --user=$user --password=$password start $2
        ;;
    'stop' )
        "$mysqld_multi" --defaults-extra-file=$conf --user=$user --password=$password stop $2
        ;;
    'report' )
        "$mysqld_multi" --defaults-extra-file=$conf --user=$user --password=$password report $2
        ;;
    'restart' )
        "$mysqld_multi" --defaults-extra-file=$conf --user=$user --password=$password stop $2
        "$mysqld_multi" --defaults-extra-file=$conf --user=$user --password=$password start $2
        ;;
    *)
        echo "Usage: $0 {start|stop|report|restart}" >&2
        ;;
esac
```

7. 多实例MySQL登录
---------
因为我们配置了多实例，在配置文件中指定了不同的sock文件，因此在服务器本地登录MySQL时需要指定sock文件。
```shell
# mysql -uroot -p -S /tmp/mysql.sock1
# mysql -uroot -p -S /tmp/mysql.sock2
```
