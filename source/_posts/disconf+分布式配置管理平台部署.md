---
title: disconf分布式配置管理平台部署
date: 2017-01-26
categories: 
 - Linux
 - Disconf

tags: 
 - disconf
 - 分布式
 - 配置管理

---
**1. 前言**
======
>Disconf是由百度开源的一套分布式配置管理平台（Distributed Configuration Management Platform），专注于各种「分布式系统配置管理」的「通用组件」和「通用平台」, 提供统一的「配置管理服务」。
首先，实现了同构系统的配置发布统一化，提供了配置服务server，该服务可以对配置进行持久化管理并对外提供restful接口，在此基础上，基于zookeeper实现对配置更改的实时推送，并且，提供了稳定有效的容灾方案，以及用户体验良好的编程模型和WEB用户管理界面。其次，实现了异构系统的配置包管理，提出基于zookeeper的全局分布式一致性锁来实现主备统一部署、系统异常时的主备自主切换。

**2. 配置前准备工作**
======
**部署规划**
------
>Disconf分为web端与client端，web端统一管理各个环境的配置，在此我们只需要部署web端即可。
Disconf的部署非常简单，它是java语言开发的程序，部署时只需将war包部署到相应位置即可运行，因此只需要在JDK+Tomcat环境中将disconf的war包部署即可。
为保证高可用，我们将disconf分别部署到三台服务器上，并在前端采用nginx实现动静分离+负载均衡。
disconf依赖tomcat环境部署路径：
/usr/local/disconf-tomcat/
disconf部署路径：
/home/disconf/war
disconf打包前配置文件存放路径：
/home/disconf/conf/
disconf日志文件存放路径：
/home/disconf/log/
disconf前端静态文件存放路径：
/home/disconf/war/html/
disconf-web监听端口：8085
disconf前端nginx监听端口：8888


<!-- more -->


**准备安装程序**
------
```
# ls /home/soft/disconf/
apache-maven-3.3.9-bin.tar.gz  apache-tomcat-8.0.39.tar.gz
# tar zxf apache-maven-3.3.9-bin.tar.gz
# tar zxf apache-tomcat-8.0.39.tar.gz
# ls
apache-maven-3.3.9  apache-maven-3.3.9-bin.tar.gz  apache-tomcat-8.0.39  apache-tomcat-8.0.39.tar.gz
```
**创建相关安装目录**
------
```
# mkdir -pv /home/disconf/{conf,war,log}
mkdir: created directory `/home/disconf'
mkdir: created directory `/home/disconf/conf'
mkdir: created directory `/home/disconf/war'
mkdir: created directory `/home/disconf/log'
```
**3. 部署配置Disconf**
======
**3.1 安装配置JDK环境**
------
disconf是采用JAVA语言开发的程序，所以需要先安装配置JDK环境，本次因为我们部署disconf的服务器已配置过JDK环境，故在此略过配置详细步骤。

**3.2. 部署配置MAVEN**
------
因为最新版本的disconf仅提供源码，因此需要我们将源码下载到服务器，然后通过maven来打包，所以我们要先部署maven环境，只需在其中一台服务器上部署maven即可。
```
# mv apache-maven-3.3.9 /usr/local/maven
# vim /etc/profile.d/maven.sh
export MAVEN_HOME=/usr/local/maven
export PATH=$MAVEN_HOME/bin:$PATH

# source /etc/profile.d/maven.sh 
# mvn -v
Apache Maven 3.3.9 (bb52d8502b132ec0a5a3f4c09453c07478323dc5; 2015-11-11T00:41:47+08:00)
Maven home: /usr/local/maven
Java version: 1.8.0_111, vendor: Oracle Corporation
Java home: /usr/java/jdk1.8.0_111/jre
Default locale: en_US, platform encoding: UTF-8
OS name: "linux", version: "2.6.32-642.4.2.el6.x86_64", arch: "amd64", family: "unix"
```
maven默认中央仓库为apache官方，在国内使用速度是相当之慢，因此，建议将中央仓库修改为阿里云仓库。
```
# vim /usr/local/maven/conf/settings.xml
添加如下配置：
  <mirrors>
    <mirror>
      <id>alimaven</id>
      <name>aliyun maven</name>
      <url>http://maven.aliyun.com/nexus/content/groups/public/</url>
      <mirrorOf>central</mirrorOf>        
    </mirror>
  </mirrors>
```
maven配置成功。

**3.3 为Disconf准备MySQL数据库环境**
------
在MySQL服务器上创建数据库disconf并设置相应的用户。
```
mysql> create database disconf;
Query OK, 1 row affected (0.00 sec)

mysql> grant all privileges on disconf.* to 'disconf'@'192.168.1.%' identified by 'bh7F3d0djPhkTcp9D';
Query OK, 0 rows affected, 1 warning (0.00 sec)

mysql> flush privileges;
Query OK, 0 rows affected (0.00 sec)
```
将disconf源码目录下的sql文件上传到MySQL服务器上，并按照readme.md文件中的说明，依此导入sql文件。
```
# pwd
/home/soft/disconf/disconf-master/disconf-web/sql
# ls
0-init_table.sql  1-init_data.sql  201512  20160701  deprecated  readme.md
# more readme.md 
为了方便大家开发，统一了所有SQL，请先后执行：

- 0-init_table.sql        create db,tables
- 1-init_data.sql         create data
- 201512/20151225.sql     patch
- 20160701/20160701.sql   patch

mysql> source /home/soft/sql/0-init_table.sql
Query OK, 1 row affected, 1 warning (0.00 sec)

Database changed
Query OK, 0 rows affected (0.01 sec)

Query OK, 0 rows affected (0.01 sec)

Query OK, 0 rows affected (0.01 sec)

Query OK, 0 rows affected (0.01 sec)

Query OK, 0 rows affected (0.01 sec)

Query OK, 0 rows affected (0.01 sec)

mysql> source /home/soft/sql/1-init_data.sql
Query OK, 1 row affected (0.00 sec)

Query OK, 16 rows affected (0.00 sec)
Records: 16  Duplicates: 0  Warnings: 0

Query OK, 4 rows affected (0.00 sec)
Records: 4  Duplicates: 0  Warnings: 0

Query OK, 3 rows affected (0.00 sec)
Records: 3  Duplicates: 0  Warnings: 0

Query OK, 72 rows affected (0.00 sec)
Records: 72  Duplicates: 0  Warnings: 0

Query OK, 8 rows affected (0.00 sec)
Records: 8  Duplicates: 0  Warnings: 0

mysql> source /home/soft/sql/201512/20151225.sql
Query OK, 0 rows affected (0.01 sec)

Query OK, 0 rows affected (0.03 sec)
Records: 0  Duplicates: 0  Warnings: 0

mysql> source /home/soft/sql/20160701/20160701.sql
Query OK, 0 rows affected (0.02 sec)
Records: 0  Duplicates: 0  Warnings: 0

Query OK, 3 rows affected (0.00 sec)
Records: 3  Duplicates: 0  Warnings: 0

mysql> show tables;
+-------------------+
| Tables_in_disconf |
+-------------------+
| app               |
| config            |
| config_history    |
| env               |
| role              |
| role_resource     |
| user              |
+-------------------+
7 rows in set (0.00 sec)
出现上面7个表，就说明数据库初始化成功。
```

**3.4 下载并打包disconf-web**
------
```
# ls /home/soft/disconf/
disconf-master.zip
# unzip disconf-master.zip
# ls
disconf-master  disconf-master.zip
# pwd
/home/soft/disconf/disconf-master
```
将mvn编译打包需要的文件拷贝到/home/disconf/conf目录下。
```
# cp disconf-web/profile/rd/* /home/disconf/conf/
# cd /home/disconf/conf/
# ls
application-demo.properties  jdbc-mysql.properties  log4j.properties  logback.xml  redis-config.properties  zoo.properties
# mv application-demo.properties application.properties 
# ls
application.properties  jdbc-mysql.properties  log4j.properties  logback.xml  redis-config.properties  zoo.properties
切记，一定要将配置文件application-demo.properties修改为application.properties
```
修改配置文件
```
# vim jdbc-mysql.properties
jdbc.driverClassName=com.mysql.jdbc.Driver

jdbc.db_0.url=jdbc:mysql://192.168.1.110:3306/disconf?useUnicode=true&characterEncoding=utf8&zeroDateTimeBehavior=convertToNull&rewriteBatchedStatements=false
jdbc.db_0.username=disconf
jdbc.db_0.password=bh7F3d0djPhkTcp9D

jdbc.maxPoolSize=20
jdbc.minPoolSize=10
jdbc.initialPoolSize=10
jdbc.idleConnectionTestPeriod=1200
jdbc.maxIdleTime=3600

# vim log4j.properties
log4j.rootLogger=INFO,dailyRolling,CONSOLE

log4j.logger.org.apache.zookeeper=WARN
log4j.logger.org.springframework=INFO
log4j.logger.org.springframework.aop.framework.Cglib2AopProxy = INFO

log4j.appender.dailyRolling=org.apache.log4j.DailyRollingFileAppender
log4j.appender.dailyRolling.File=/home/disconf/log/disconf-log4j.log
log4j.appender.dailyRolling.layout=org.apache.log4j.PatternLayout
log4j.appender.dailyRolling.layout.ConversionPattern=%d [%t] %-5p %-17c{2} (%13F:%L) %3x - %m%n

log4j.appender.Threshold=WARN
log4j.appender.CONSOLE=org.apache.log4j.ConsoleAppender
log4j.appender.CONSOLE.Target=System.out
log4j.appender.CONSOLE.layout=org.apache.log4j.PatternLayout
log4j.appender.CONSOLE.layout.ConversionPattern=%d [%t] %-5p %-17c{2} (%13F:%L) %3x - %m%n

# vim redis-config.properties
redis.group1.retry.times=2

redis.group1.client1.name=BeidouRedis1
redis.group1.client1.host=192.168.1.5
redis.group1.client1.port=6379
redis.group1.client1.timeout=5000
redis.group1.client1.password=foobared

redis.group1.client2.name=BeidouRedis2
redis.group1.client2.host=192.168.1.6
redis.group1.client2.port=6379
redis.group1.client2.timeout=5000
redis.group1.client2.password=foobared

redis.group1.client3.name=BeidouRedis3
redis.group1.client3.host=192.168.1.7
redis.group1.client3.port=6379
redis.group1.client3.timeout=5000
redis.group1.client3.password=foobared

redis.evictor.delayCheckSeconds=300
redis.evictor.checkPeriodSeconds=30
redis.evictor.failedTimesToBeTickOut=6

# vim zoo.properties
hosts=192.168.1.104:2181,192.168.1.105:2181,192.168.1.106:2181

# zookeeper\u7684\u524D\u7F00\u8DEF\u5F84\u540D
zookeeper_url_prefix=/disconf
```
编译disconf源文件，生成war包
```
# pwd
/home/soft/disconf/disconf-master
# mvn clean install
这一步如果报错，可以忽略。

设置环境变量
# vim /etc/profile.d/war.sh
export ONLINE_CONFIG_PATH=/home/disconf/conf
export WAR_ROOT_PATH=/home/disconf/war
# source /etc/profile.d/war.sh

执行编译脚本
# cd disconf-web/
# pwd
/home/soft/disconf/disconf-master/disconf-web
# sh deploy/deploy.sh

编译结束后，会在$WAR_ROOT_PATH位置下生成如下文件：
# ls /home/disconf/war/
application.properties  disconf-web.war  html  jdbc-mysql.properties  jpaas_control  log4j.properties  logback.xml  META-INF  redis-config.properties  Release  WEB-INF  zoo.properties
```
**3.5 部署配置nginx+tomcat**
------
nginx与tomcat的部署，在之前的文档有过详细说明，在此不赘述。

修改tomcat配置文件
```
# vim /usr/local/disconf-tomcat/conf/server.xml
    <Connector port="8085" protocol="HTTP/1.1"
               connectionTimeout="20000"
               redirectPort="8443" />

      <Host name="localhost"  appBase="webapps"
            unpackWARs="true" autoDeploy="true">

        <Context path="" docBase="/home/disconf/war"></Context>

```
修改nginx配置文件
```
# vim /usr/local/openresty/nginx/conf/nginx.conf
    upstream disconf {
    server 192.168.1.104:8085 weight=10 max_fails=2 fail_timeout=30s;
    }

    server {
        listen       8888;
        server_name  localhost;

        #charset koi8-r;
        charset utf-8;

        #access_log  logs/host.access.log  main;
        access_log  logs/disconf.access.log  main;
        error_log   logs/disconf.error.log;

        #location / {
        #    root   html;
        #    index  index.html index.htm;
        #}

        location / {
            root /home/disconf/war/html;
            if ($query_string) {
                expires max;
            }
        }
        location ~ ^/(api|export) {
            proxy_pass_header Server;
            proxy_set_header Host $http_host;
            proxy_redirect off;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Scheme $scheme;
            proxy_pass http://disconf;
        }

```
分别启动nginx、tomcat服务。

**3.6 访问Disconf Web页面测试**
------
```
http://192.168.1.104:8888/

使用用户名密码admin/admin正常登陆，disconf配置完成。
```



