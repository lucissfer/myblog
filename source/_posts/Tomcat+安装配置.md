---
title: Tomcat安装配置
date: 2017-01-10
categories: 
 - Linux
 - Tomcat

tags: 
 - tomcat
 - 安装配置

---

**安装JDK**
```
# rpm -ivh jdk-8u111-linux-x64.rpm
```
**配置JAVA环境变量**
```
# vim /etc/profile.d/java.sh
export JAVA_HOME=/usr/java/latest
export PATH=$JAVA_HOME/bin:$PATH
```
**导出环境变量**
```
# source /etc/profile.d/java.sh
```
**查看JAVA版本**
```
# java -version
```
**解压tomcat到指定目录**
```
# tar zxf apache-tomcat-8.0.39.tar.gz -C /usr/local/
# ln -s /usr/local/apache-tomcat-8.0.39/ /usr/local/tomcat
```
**配置tomcat环境变量**
```
# vim /etc/profile.d/tomcat.sh
export CATALINA_HOME=/usr/local/tomcat
export PATH=$CATALINA_HOME/bin:$PATH
```

<!-- more -->

**导出tomcat环境变量**
```
# source /etc/profile.d/tomcat.sh
```
**查看tomcat版本**
```
# catalina.sh version
```
**启动tomcat**
```
# catalina.sh start
```
**隐藏tomcat版本信息**
```
在线上生产环境中，为了防止tomcat版本信息暴露导致的恶意攻击，我们需要将tomcat版本隐藏
# cd $CATALINA_HOME/lib/
# unzip catalina.jar
# vim org/apache/catalina/util/ServerInfo.properties
server.info=Apache Tomcat/X
server.number=X

# jar uvf catalina.jar org/apache/catalina/util/ServerInfo.properties
# catalina.sh stop
# catalina.sh start
```