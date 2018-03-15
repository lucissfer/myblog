---
title: Redis报错：Redis is configured to save RDB snapshots
date: 2016-08-26
categories: 
 - Linux
 - Redis

tags: 
 - redis
 - 故障报错

---

上午刚上班没一会，测试的兄弟找过来内网的redis服务连不上了，web访问redis的时候报错：
>-MISCONF Redis is configured to save RDB snapshots, but is currently not able to persist on disk. Commands that may modify the data set are disabled. Please check Redis logs for details about the error. 

赶紧登录服务器检查；端口监听正常，进程正常，在服务器上使用redis-cli客户端进入redis，使用命令
```shell
127.0.0.1:6379> keys *
```
顺利得到结果，说明redis服务是正常的，那么为毛web端无法连接呢？
赶紧查查redis日志，but，找了半天没发现redis日志在哪，翻了下配置文件，那一刻我**震惊了**！
```
logfile ""
你特么是在逗我!!
```
不知道之前是哪位“大神”配置的，居然没有指定日志文件路径，我勒个擦擦！
好吧，那让我再仔细瞅瞅这个报错吧。
以我英语四级差一点就过了的水准，仔细瞅了瞅这一大串英文字母，貌似是在说redis不能在硬盘上持久化，那一刻**瞬间灵光一闪**：
>这特么不会又是磁盘空间满了吧？（我为什么要说又呢）


<!-- more -->


赶紧祭出神器：
```shell
# df -hl
```
看看结果，果然是磁盘满了，然后使用另一神器查询到底是哪个文件吃了熊心豹子胆，胆敢耗完整个磁盘空间，过程略过不表，但看结果：
![redis-error-01][1]

妹的，一个zookeeper.out文件就把空间用完了，又是这帮开发干的，之前用kafka也是，日志能把整个硬盘空间占完，我也是无话可说，果断一条命令：
```shell
# echo '' > zookeeper.out
```
web端重新连接，一切正常，结果就是这么简单。
之后，用Google搜索了一下报错信息，发现了很多不同的解答，但是没有与我的情况一致的，因此在这里提醒一下：
> 如果服务器上redis进程服务正常的情况下，客户端连接redis报错：*-MISCONF Redis is configured to save RDB snapshots, but is currently not able to persist on disk. Commands that may modify the data set are disabled. Please check Redis logs for details about the error.*
请先检查下磁盘空间是否正常，很有可能是磁盘空间不够用哦，不过如果你的服务器磁盘空间有监控的话，应该是不难发现这个问题的。

  [1]: http://7xvqp4.com1.z0.glb.clouddn.com/image/jpg/20160826/redis-error-01.png