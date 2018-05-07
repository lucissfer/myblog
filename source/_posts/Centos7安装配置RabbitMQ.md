---
title: Centos7安装配置RabbitMQ
date: 2018-05-07
categories: 
 - Linux
 - Centos
 - RabbitMQ

tags: 
 - Centos
 - RabbitMQ

---
**1. RabbitMQ介绍**
======
> RabbitMQ是实现AMQP（高级消息队列协议）的消息中间件的一种，最初起源于金融系统，用于在分布式系统中存储转发消息，在易用性、扩展性、高可用性等方面表现不俗。RabbitMQ主要是为了实现系统之间的双向解耦而实现的。当生产者大量产生数据时，消费者无法快速消费，那么需要一个中间层。保存这个数据。

> AMQP，即Advanced Message Queuing Protocol，高级消息队列协议，是应用层协议的一个开放标准，为面向消息的中间件设计。消息中间件主要用于组件之间的解耦，消息的发送者无需知道消息使用者的存在，反之亦然。AMQP的主要特征是面向消息、队列、路由（包括点对点和发布/订阅）、可靠性、安全。

> RabbitMQ是一个开源的AMQP实现，服务器端用Erlang语言编写，支持多种客户端，如：Python、Ruby、.NET、Java、JMS、C、PHP、ActionScript、XMPP、STOMP等，支持AJAX。用于在分布式系统中存储转发消息，在易用性、扩展性、高可用性等方面表现不俗。

>                                                       ---以上内容我抄的


<!-- more -->

**2. 准备所需软件包**
======
```shell
# ls /data/src/
jdk-8u171-linux-x64.rpm  otp_src_18.3.tar.gz  rabbitmq-server-generic-unix-3.6.6.tar   wxWidgets-3.0.4.tar
```

**3. 编译安装Erlang** 
======
因为RabbitMQ是用Erlang语言编写的，所以在编译安装RabbitMQ之前必须要先编译安装Erlang，Erlang的安装可以使用yum安装，也可以使用源码包编译安装；Centos7上yum安装的Erlang版本太低，因此，此处我们采用源码包编译安装。
**3.1 安装依赖环境**
------
```shell
# yum install -y gcc*
# yum install -y ncurses-devel
# yum install -y unixODBC unixODBC-devel
# yum install -y openssl-devel
# yum install -y mesa* freeglut*
# yum install -y fop
# yum install -y libxslt-devel
```
**3.2 编译安装wxWidgets**
------
wxWidgets是一个开源的跨平台的C++构架库（framework），它可以提供GUI（图形用户界面）和其它工具。wxWidgets支持在Erlang的编译安装过程中是非必需的，但Erlang的新GUI工具是基于wxWidgets开发的，因此要使用这些工具必须安装wxWidgets。
```shell
# wget https://github.com/wxWidgets/wxWidgets/releases/download/v3.0.4/wxWidgets-3.0.4.tar.bz2
# bzip2 -d wxWidgets-3.0.4.tar.bz2
# tar xf wxWidgets-3.0.4.tar
# cd wxWidgets-3.0.4/
# yum install -y gtk+-devel
# yum install -y gtk2-devel binutils-devel
# ./configure --with-opengl --enable-debug --enable-unicode
# make && make install
```
> **注意：**
此处需注意的是，gtk+-devel、gtk2-devel、binutils-devel是必需的依赖环境，否则wxWidgets的make过程会报错。

**3.3 编译安装Erlang**
------
```shell
# tar zxf otp_src_18.3.tar.gz
# cd otp_src_18.3
# ./configure
# make && make install
```
测试Erlang是否安装成功
```shell
# erl
Erlang/OTP 18 [erts-7.3] [source] [64-bit] [smp:4:4] [async-threads:10] [kernel-poll:false]

Eshell V7.3  (abort with ^G)
1> halt().
```

**4. 安装配置RabbitMQ**
======
RabbitMQ提供了yum安装、rpm安装、编译安装、二进制包等多种方式，此处采用的是二进制包直接解压使用。
**4.1 解压RabbitMQ二进制包并移动到指定目录**
------
```shell
# tar xf rabbitmq-server-generic-unix-3.6.6.tar
# mv rabbitmq_server-3.6.6 /data/program/rabbitmq
```
配置环境变量
```shell
# vim /etc/profile.d/rabbitmq.sh
export PATH=/data/program/rabbitmq/sbin:$PATH
# source /etc/profile
```
**4.2 启动RabbitMQ服务**
------
```shell
# rabbitmq-server -detached
# rabbitmqctl status
```
**4.3 开启web管理接口**
------
RabbitMQ默认情况下近允许通过命令行来管理，在日常工作中多有不便，还好RabbitMQ自带了web管理界面，只需要启动插件便可以使用。
```shell
# rabbitmq-plugins enable rabbitmq_management
```
使用浏览器访问
> http://[IP]:15672

输入用户名和密码就可以访问web管理界面了。

**4.4 配置RabbitMQ用户**
------
默认情况下，RabbitMQ的默认的guest用户只允许本机访问，如果需要远程访问，可以新增一个用户并配置远程；同时，由于RabbitMQ默认的账号用户名和密码都是guest。为了安全起见, 先删掉默认用户。

**新增远程管理用户rabbitmq**
```shell
# rabbitmqctl add_user rabbitmq password
# rabbitmqctl set_permissions -p "/" rabbitmq ".*" ".*" ".*"
# rabbitmqctl set_user_tags rabbitmq administrator
```
**删除默认用户guest**
```shell
# rabbitmqctl delete_user guest
Deleting user "guest" ...
```

**4.5 RabbitMQ常用命令**
------
```shell
查看当前所有用户
# rabbitmqctl list_users
Listing users ...
rabbitmq	[administrator]

查看默认guest用户的权限
# rabbitmqctl list_user_permissions guest

添加新用户
# rabbitmqctl add_user username password

设置用户tag
# rabbitmqctl set_user_tags username administrator

赋予用户默认vhost的全部操作权限
# rabbitmqctl set_permissions -p / username ".*" ".*" ".*"

查看用户的权限
# rabbitmqctl list_user_permissions username
```
**4.6 RabbitMQ用户角色**
------
**RabbitMQ的用户角色分类：**
> none、management、policymaker、monitoring、administrator

**RabbitMQ各类角色描述：**
> **none**
不能访问 management plugin

> **management**
用户可以通过AMQP做的任何事外加：
列出自己可以通过AMQP登入的virtual hosts  
查看自己的virtual hosts中的queues, exchanges 和 bindings
查看和关闭自己的channels 和 connections
查看有关自己的virtual hosts的“全局”的统计信息，包含其他用户在这些virtual hosts中的活动。

> **policymaker** 
management可以做的任何事外加：
查看、创建和删除自己的virtual hosts所属的policies和parameters

> **monitoring**  
management可以做的任何事外加：
列出所有virtual hosts，包括他们不能登录的virtual hosts
查看其他用户的connections和channels
查看节点级别的数据如clustering和memory使用情况
查看真正的关于所有virtual hosts的全局的统计信息

> **administrator**  
policymaker和monitoring可以做的任何事外加:
创建和删除virtual hosts
查看、创建和删除users
查看创建和删除permissions
关闭其他用户的connections

**5. 一些踩到的坑**
======
**5.1 关于编译环境**
------
编译安装Erlang的时候会出现报错：
> jinterface : No Java compiler found

可以通过安装jdk来解决，如果有gcc环境，无需安装jdk，可以在configure时增加 –disable-javac来跳过警告。

**5.2 重启服务器后，RabbitMQ用户丢失问题**
------
在部署配置完成后，重启了一次服务器，服务器启动后重新启动RabbitMQ服务，结果神奇的发现RabbitMQ用户丢失了。
原因如下：
```shell
RabbitMQ数据是根据当前hostname作为node节点作为数据名保存
# ls /data/program/rabbitmq/var/lib/rabbitmq/mnesia/
rabbit@Centos7-01  rabbit@Centos7-01.pid  rabbit@Centos7-01-plugins-expand
```
重启服务器之前我修改了hostname，所以重启之后，RabbitMQ服务使用新的hostname来保存数据。

可以通过添加RabbitMQ固定节点名字，保证数据文件不变。
```shell
# echo 'NODENAME=rabbit@info' | tee -a etc/rabbitmq/rabbitmq-env.conf
```
