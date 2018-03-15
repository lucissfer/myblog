---
title: Centos环境搭建shadowsocks科学上网
date: 2016-10-12
categories: Linux
tags: 
 - Centos
 - shadowsocks
 - 科学上网

---

> **前言：**作为一名IT技术狗，在日常工作学习中，难免会经常使用搜索引擎来搜索技术问题，而众所周知的是百度在技术搜索上就是个笑话，想要快速找到答案还是得靠Google，但是因为某些不可描述的原因，在国内想通过正规途径来访问Google完全是不可能的。
那么问题来了，如何通过一些技术小手段来正常访问Google呢？一般来说，常见的方法是通过国外线路的VPN来访问，然而这种情况下有一些使用上的不便。比如说：*很多时候在解决问题的时候我们会有这样的需求，一边使用VPN线路通过Google来搜索技术问题同时还需要通过QQ等即时通信软件与同事朋友交流沟通，此时因为我们通过VPN线路来上网，那么就会出现QQ异地登录警告，严重时腾讯会直接将QQ冻结*。所以，对于日常工作来说，我认为VPN太重，我们需要一个轻量级的工具仅需能够代理浏览器的请求即可，那么这时shadowsocks就是最好的选择了。

1.安装python-pip
--------
Pip是安装Python包的工具，提供了安装、列举已安装包、升级以及卸载包的功能。Pip 是对easy_install的取代，提供了和easy_install相同的查找包的功能，因此可以使用easy_install安装的包也同样可以使用pip进行安装。
目前有很多Python程序都是可以直接通过Pip来一键安装了，比如众所周知的Django、Markdown、Shadowsocks等。
```shell
# yum install -y python-pip
```

<!-- more -->

2.通过pip安装shadowsocks
--------
```shell
# pip install shadowsocks
/usr/lib/python2.6/site-packages/pip/_vendor/requests/packages/urllib3/util/ssl_.py:90: InsecurePlatformWarning: A true SSLContext object is not available. This prevents urllib3 from configuring SSL appropriately and may cause certain SSL connections to fail. For more information, see https://urllib3.readthedocs.org/en/latest/security.html#insecureplatformwarning.
  InsecurePlatformWarning
You are using pip version 7.1.0, however version 8.1.2 is available.
You should consider upgrading via the 'pip install --upgrade pip' command.
Collecting shadowsocks
/usr/lib/python2.6/site-packages/pip/_vendor/requests/packages/urllib3/util/ssl_.py:90: InsecurePlatformWarning: A true SSLContext object is not available. This prevents urllib3 from configuring SSL appropriately and may cause certain SSL connections to fail. For more information, see https://urllib3.readthedocs.org/en/latest/security.html#insecureplatformwarning.
  InsecurePlatformWarning
  Downloading shadowsocks-2.8.2.tar.gz
Installing collected packages: shadowsocks
  Running setup.py install for shadowsocks
Successfully installed shadowsocks-2.8.2

```
3.创建shadowsocks配置文件
---------
shadowsocks安装完成后默认是没有配置文件的，这时候就需要我们自己来创建配置文件，配置文件为json格式，很简单。
```shell
# vim /etc/shadowsocks.json

{
    "server":"your_server_ip",
    "server_port":8989,
    "local_address": "127.0.0.1",   #这一行可不写
    "local_port":1080,
    "password":"yourpassword",
    "timeout":600,
    "method":"aes-256-cfb",
    "fast_open": false,     #这一行可不写
    "workers": 1    #这一行可不写
}
```
**配置文件各字段含义：**
各字段的含义：
**server：**服务器 IP (IPv4/IPv6)，注意这也将是服务端监听的 IP 地址
**server_port：**监听的服务器端口
**local_address：**本地监听的 IP 地址
**local_port：**本地端端口
**password：**用来加密的密码
**timeout：**超时时间（秒）
**method：**加密方法，可选择 “bf-cfb”, “aes-256-cfb”, “des-cfb”, “rc4”, 等等。默认是一种不安全的加密，推荐用 “aes-256-cfb”
**fast_open :** true 或 false。如果你的服务器 Linux 内核在3.7+，可以开启 fast_open 以降低延迟。开启方法：
```shell
# echo 3 > /proc/sys/net/ipv4/tcp_fastopen
```
开启之后，将 fast_open 的配置设置为 true 即可。
**works :** works数量，默认为 1
这一段参考：https://teddysun.com/339.html

4.服务器端启动shadowsocks
-------
在服务器端启动shadowsocks有很多方法，此处我们使用的是指定配置文件启动。
```shell
# ssserver -c /etc/shadowsocks.json
```
但这种启动方式将一直启动在当前会话，所以，我们要将其放入后台启动，同时还可以指定记录日志。
```shell
# nohup ssserver -c /etc/shadowsocks.json 2> /var/log/shaowsocks.log &
```
将启动命令写入/etc/rc.local设置为开机启动
```shell
echo "nohup ssserver -c /etc/shadowsocks.json 2> /var/log/shaowsocks.log &" >> /etc/rc.local
```
查看端口是否监听，判断服务是否正常启动
```shell
# netstat -nultp
Active Internet connections (only servers)
Proto Recv-Q Send-Q Local Address               Foreign Address             State       PID/Program name   
tcp        0      0 0.0.0.0:8989                0.0.0.0:*                   LISTEN      31593/python
```
如果端口没有监听，那么一定是启动过程中出错了，直接根据报错提示排错，我在配置过程中也出了一次错误。
```shell
# ssserver -c /etc/shadowsocks.json
INFO: loading config from /etc/shadowsocks.json
/usr/lib/python2.6/site-packages/shadowsocks/shell.py:154: DeprecationWarning: BaseException.message has been deprecated as of Python 2.6
  e.message)
ERROR: found an error in config.json: Expecting property name: line 9 column 1 (char 189)
```
其实这个错误提示很明显，配置文件第9行出错，检查了下shadowsocks.json发现，第9行多写了一个","
5.添加防火墙规则
---------
```shell
# iptables -I INPUT -p tcp --dport 8489 -j ACCEPT
```
至此，服务器端的 Shadowsocks 安装和配置完毕。

6.shadowsocks客户端配置
--------
shadowsocks客户端配置非常简单，自行百度即可。
