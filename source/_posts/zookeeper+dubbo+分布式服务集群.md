---
title: zookeeper+dubbo部署分布式服务集群
date: 2017-02-01
categories: 
 - Linux
 - Zookeeper
 - Dubbo

tags: 
 - zookeeper
 - dubbo
 - 分布式服务

---
**1. 配置前准备工作**
======
**部署规划**
------
>集群使用三台服务器，分别部署zookeeper、dubbo-admin服务，其中zookeeper分别部署在三台服务器上，dubbo-admin部署于三台服务器其中一台上，三台zookeeper构成集群，而dubbo-admin是否正常对于dubbo服务正常运行并不会造成任何影响，因此dubbo采用单点部署。
zookeeper安装路径：
/usr/local/zookeeper-3.4.6/
链接至
/usr/local/zookeeper/
zookeeper数据存放路径
/home/zookeeper/data/
zookeeper日志存放路径
/usr/local/zookeeper/log/
clientPort:2181
zookeeper数据交换端口:2888
zookeeper选举端口:3888

**准备安装程序**
------
```
# ls /home/soft/
dubbo-admin-tomcat.tar.gz  dubbo-monitor-simple-2.8.4-assembly.tar.gz  jdk-8u111-linux-x64.rpm  zookeeper-3.4.6.tar.gz
# tar zxf zookeeper-3.4.6.tar.gz
# mv /home/soft/zookeeper-3.4.6 /usr/local/
# ln -s /usr/local/zookeeper-3.4.6 /usr/local/zookeeper
```

**创建相关安装目录**
------
```
# mkdir -pv /home/zookeeper/data/
mkdir: created directory `/home/zookeeper'
mkdir: created directory `/home/zookeeper/data/'
# mkdir /usr/local/zookeeper/log/
```

<!-- more -->

**配置相应的iptables规则**
------
```
# iptables -I INPUT -s 10.1.1.0/24 -p tcp -j ACCEPT
# service iptables save
```

**2. 安装并配置JDK**
======
**因为zookeeper是Java语言开发的项目，所以要先安装JDK。**
**安装JDK**
------
```
# rpm -ivh jdk-8u111-linux-x64.rpm
```
**配置JAVA环境变量**
------
```
# vim /etc/profile.d/java.sh
export JAVA_HOME=/usr/java/latest
export PATH=$JAVA_HOME/bin:$PATH
```
**导出环境变量**
------
```
# source /etc/profile.d/java.sh
```
**查看Java版本**
------
```
# java -version
```

**3. 安装并配置zookeeper**
======
**准备zookeeper配置文件**
------
```
# cd /usr/local/zookeeper
# pwd
/usr/local/zookeeper
# cd conf/
# pwd
/usr/local/zookeeper/conf
# cp zoo_sample.cfg zoo.cfg
# vim zoo.cfg
tickTime=2000
initLimit=10
syncLimit=5
dataDir=/home/zookeeper/data
dataLogDir=/usr/local/zookeeper/log
clientPort=2181
server.1=10.1.1.148:2888:3888
server.2=10.1.1.149:2888:3888
server.3=10.1.1.150:2888:3888

这里的地址用IP或主机名都可以。
```
**在data目录下创建myid文件**
------
```
分别在三台服务器上创建myid文件，myid文件中的只要与配置文件中对应，依次为：
10.1.1.148
echo "1" > /home/zookeeper/data/myid
10.1.1.149
echo "2" > /home/zookeeper/data/myid
10.1.1.150
echo "3" > /home/zookeeper/data/myid
```
**启动并测试zookeeper**
------
```
# /usr/local/zookeeper/bin/zkServer.sh start
# jps -l
16691 org.apache.zookeeper.server.quorum.QuorumPeerMain
16758 sun.tools.jps.Jps
```

**4. 安装dubbo-admin并配置**
======
**安装dubbo-admin**
------
```
dubbo-admin是否正常对于dubbo服务正常运行并不会造成任何影响，因此dubbo采用单点部署，此次部署在10.1.1.148上。
# pwd
/home/soft
# tar zxf dubbo-admin-tomcat.tar.gz
# mv /home/soft/dubbo-admin-tomcat /usr/local/
# cd /usr/local/dubbo-admin-tomcat/
# ls
bin  conf  lib  LICENSE  logs  NOTICE  RELEASE-NOTES  RUNNING.txt  temp  webapps  work
```
**配置dubbo.properties**
------
```
# pwd
/usr/local/dubbo-admin-tomcat
# cd webapps/ROOT/WEB-INF/
# ls
classes  common  dubbo.properties  forms  i18n  lib  log4j.xml  templates  webx-governance.xml  webx-home.xml  web.xml  webx-personal.xml  webx-sysinfo.xml  webx-sysmanage.xml  webx.xml
# vim dubbo.properties
dubbo.registry.address=zookeeper://10.1.1.148:2181?backup=10.1.1.149:2181,10.1.1.150:2181
dubbo.admin.root.password=root
dubbo.admin.guest.password=guest
```
**启动dubbo-admin**
------
```
# /usr/local/dubbo-admin-tomcat/bin/catalina.sh start
Using CATALINA_BASE:   /usr/local/dubbo-admin-tomcat
Using CATALINA_HOME:   /usr/local/dubbo-admin-tomcat
Using CATALINA_TMPDIR: /usr/local/dubbo-admin-tomcat/temp
Using JRE_HOME:        /usr/java/latest
Using CLASSPATH:       /usr/local/dubbo-admin-tomcat/bin/bootstrap.jar:/usr/local/dubbo-admin-tomcat/bin/tomcat-juli.jar
Tomcat started.
# netstat -nultp
Active Internet connections (only servers)
Proto Recv-Q Send-Q Local Address               Foreign Address             State       PID/Program name   
tcp        0      0 127.0.0.1:25                0.0.0.0:*                   LISTEN      1005/master         
tcp        0      0 0.0.0.0:11580               0.0.0.0:*                   LISTEN      1366/sshd           
tcp        0      0 ::ffff:10.1.1.148:3888      :::*                        LISTEN      5132/java           
tcp        0      0 :::56656                    :::*                        LISTEN      5132/java           
tcp        0      0 :::8082                     :::*                        LISTEN      5241/java           
tcp        0      0 ::1:25                      :::*                        LISTEN      1005/master         
tcp        0      0 :::11580                    :::*                        LISTEN      1366/sshd           
tcp        0      0 :::2181                     :::*                        LISTEN      5132/java           
tcp        0      0 :::8010                     :::*                        LISTEN      5241/java     
```
**访问dubbo-admin web页面测试**
------
```
http://10.1.1.148:8082
```

**5. 安装dubbo-monitor并配置**
======
**安装dubbo-monitor**
------
```
dubbo-monitor也只需单点部署即可
# pwd
/home/soft
# tar zxf dubbo-monitor-simple-2.8.4-assembly.tar.gz
# mv /home/soft/dubbo-monitor-simple-2.8.4 /usr/local/dubbo-monitor
# cd /usr/local/dubbo-monitor/
# ls
bin  conf  lib
```
**配置dubbo.properties**
------
```
# pwd
/usr/local/dubbo-monitor/conf
# vim dubbo.properties
dubbo.container=log4j,spring,registry,jetty
dubbo.application.name=simple-monitor
dubbo.application.owner=kp-java
dubbo.registry.address=zookeeper://10.1.1.148:2181?backup=10.1.1.149:2181,10.1.1.150:2181
dubbo.protocol.port=7070
dubbo.jetty.port=8080
dubbo.jetty.directory=${user.home}/monitor
dubbo.charts.directory=${dubbo.jetty.directory}/charts
dubbo.statistics.directory=${user.home}/monitor/statistics
dubbo.log4j.file=logs/dubbo-monitor-simple.log
dubbo.log4j.level=WARN
```
**启动dubbo-monitor**
------
```
# /usr/local/dubbo-monitor/bin/server.sh start
```
**访问dubbo-monitor web页面测试**
------
```
http://10.1.1.149:8080
```


