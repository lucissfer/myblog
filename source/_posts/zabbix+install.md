---
title: 编译安装zabbix
date: 2016-06-20
categories: 
 - Linux
 - Zabbix 

tags: 
 - zabbix
 - 监控
 - 编译安装

---

> **前言：**
*zabbix是一个基于WEB页面提供分布式系统监视以及网络监视功能的企业级开源解决方案。基于C/S架构，支持多种采集方式和采集客户端，有专用的Agent，也支持SNMP、IPMI、JMX、Telnet、SSH等多种协议，它可以运行在Linux，Solaris，HP-UX，AIX，Free BSD，Open BSD，OS X等平台上，它将采集到的数据存放到数据库，然后对其进行分析整理，达到条件触发告警。
对于运维工作来说，zabbix是一个不可或缺的企业监控工具，本文主要出于学习的目的，对zabbix的编译安装做一下简单介绍，**在日常业务环境中还是建议直接通过yum方式或者自己打包rpm方式安装。***

# 1.安装Zabbix-Server
安装平台为CentOS 6.7，使用Zabbix版本为2.4.7，下载地址：http://sourceforge.net/projects/zabbix/files/ZABBIX%20Latest%20Stable/2.4.7/zabbix-2.4.7.tar.gz/download
## 1.1 安装依赖包
```
# yum install -y gcc gcc-c++ autoconf httpd php mysql mysql-server php-mysql httpd-manual mod_ssl mod_perl mod_auth_mysql php-gd php-xml php-mbstring php-ldap php-pear php-xmlrpc php-bcmath mysql-connector-odbc mysql-devel libdbi-dbd-mysql net-snmp-devel curl-devel unixODBC-devel OpenIPMI-devel java-devel
```
此处，为了方便，使用的MySQL、PHP环境为yum安装，当然如果你出于学习考虑，也可以自己编译安装MySQL、PHP。

## 1.2 配置PHP环境
```
# vim /etc/php.ini
date.timezone =Asia/Shanghai
max_execution_time = 300
post_max_size = 128M
max_input_time = 300
memory_limit = 128M
mbstring.func_overload = 2
```
## 1.3 安装Zabbix-Server
下载程序源码
```
# wget http://sourceforge.net/projects/zabbix/files/ZABBIX%20Latest%20Stable/2.4.7/zabbix-2.4.7.tar.gz/download
依据自己的需要可以下载新版本，不过生产环境中不建议使用最新的版本
```
添加zabbix用户、组
```
# groupadd zabbix -g 201
# useradd -g zabbix -u 201 -m zabbix
```
解压源码包
```
# tar zxvf zabbix-2.4.7.tar.gz
```
编译安装
```
# cd zabbix-2.4.7   # 此处根据你自己的程序版本号确定目录
# ./configure --prefix=/usr --sysconfdir=/etc/zabbix --enable-server --enable-procy --enable-agent --enable-ipv6 --with-mysql=/usr/bin/mysql_config --with-net-snmp --with-libcurl -with-openipmi --with-unixodbc --with-ldap --with-ssh2 --enable-java
此处如果是自己编译的MySQL，--with-mysql后要填写正确的路径。
如果configure过程出现报错，可根据报错提示通过yum方式安装缺少的软件即可。
如果出现报错：configure: error: SSH2 library not found
只需yum install -y libssh2-devel安装这个依赖包就OK了。
如果出现报错：configure: error: Invalid LDAP directory - unable to find ldap.h
只需yum install -y openldap openldap-devel即可。

出现Thank you for using Zabbix!提示的时候，代表configure检查通过

# make && make install
```
## 1.4 导入数据库
创建zabbix相关数据库
```
# pwd
/root/zabbix-2.4.7
# chkconfig mysqld on
# service mysqld start
# mysqladmin -uroot password '1qazxsw2#'
第一次登陆MySQL的时候，需要指定MySQL root用户密码。
# mysql -u root -p
mysql> create database zabbix character set utf8;
此处注意，数据库字符集如果不是utf8，WEB界面改成中文时会出现乱码。
mysql> grant all privileges on zabbix.* to zabbix@localhost identified by 'zabbix';
mysql> flush privileges;
# mysql -uzabbix -pzabbix zabbix
测试zabbix数据库连接正常。
```
导入数据库
```
# mysql -uzabbix -pzabbix zabbix < ./database/mysql/schema.sql
```
***注意，如果只安装Proxy，则只导入schema.sql即可，无须导入下面的SQL，否则将导致Proxy无法正常工作。***
```
# mysql -uzabbix -pzabbix zabbix < ./database/mysql/images.sql 
# mysql -uzabbix -pzabbix zabbix < ./database/mysql/data.sql
```
为zabbix创建日志文件夹
```
# mkdir /var/log/zabbix
# chown -R zabbix:zabbix /var/log/zabbix/
```
## 1.5 复制Service启动脚本
```
# cp misc/init.d/fedora/core/zabbix_* /etc/init.d/
# chmod 755 /etc/init.d/zabbix_*
# sed -i "s@BASEDIR=/usr/local@BASEDIR=/usr/@g" /etc/init.d/zabbix_server 
# sed -i "s@BASEDIR=/usr/local@BASEDIR=/usr/@g" /etc/init.d/zabbix_agentd
此处，如果编译前配置指定的安装路径为/usr/local则无须sed操作。
```
## 1.6 配置zabbix_server.conf服务器端文件
路径：/etc/zabbix/zabbix_server.conf
修改下列参数即可正常工作。
```
DBName=zabbix
DBUser=zabbix
DBPassword=zabbix
```
## 1.7 复制网页文件到Apache目录
```
# pwd
/root/zabbix-2.4.7
# cp -r  ./frontends/php/ /var/www/html/zabbix 
# chown -R apache:apache /var/www/html/zabbix/
```
启动zabbix服务。
```
# chkconfig zabbix_server on
# chkconfig zabbix_agentd on
# service zabbix_server start
# service zabbix_agentd start
# chkconfig httpd on
# service httpd start
```
## 1.8 添加相应防火墙规则
```
# iptables -A INPUT -m state --state NEW -m tcp -p tcp --dport 80 -j ACCEPT
# iptables -A INPUT -m state --state NEW -m tcp -p tcp --dport 10050 -j ACCEPT
# iptables -A INPUT -m state --state NEW -m tcp -p tcp --dport 10051 -j ACCEPT
# iptables -A INPUT -m state --state NEW -m udp -p udp --dport 10050 -j ACCEPT
# iptables -A INPUT -m state --state NEW -m udp -p udp --dport 10051 -j ACCEPT
```
关闭Selinux
```
# setenforce 0
# vim /etc/selinux/config

```
至此，Zabbix的Server端安装完成。
## 1.9 配置Zabbix-Server前端UI
打开浏览器，访问http://[IP]/zabbix，