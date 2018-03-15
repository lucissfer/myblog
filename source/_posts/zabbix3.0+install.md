---
title: 编译安装配置zabbix 3.0监控平台
date: 2016-12-20
categories: 
 - Linux
 - Zabbix

tags: 
 - zabbix3.0
 - 监控平台

---

**1. 前言**
======
> zabbix是一个基于WEB页面提供分布式系统监视以及网络监视功能的企业级开源解决方案。基于C/S架构，支持多种采集方式和采集客户端，有专用的Agent，也支持SNMP、IPMI、JMX、Telnet、SSH等多种协议，它可以运行在Linux，Solaris，HP-UX，AIX，Free BSD，Open BSD，OS X等平台上，它将采集到的数据存放到数据库，然后对其进行分析整理，达到条件触发告警。
对于运维工作来说，zabbix是一个不可或缺的企业监控工具，在日常业务环境中可以选择直接通过yum方式安装或者编译源码安装，因为本人喜欢将zabbix安装到自定义位置，故选择编译安装。

**2. 部署前准备工作**
======
**2.1 部署规划**
------
> zabbix目前提供了三个版本的源码包供下载安装，分别是：Zabbix 2.2 LTS、Zabbix 3.0 LTS、Zabbix 3.2。
Zabbix2.2与3.0均为LTS即Long Term Support（长期支持）版本，Zabbix LTS版本可以为客户提供5年的技术支持，包括3年的全服务支持（一般，严重和安全的问题的解决）和后2年的限制性支持（只包括严重和安全问题的解决）。LTS版本发布会改变版本号第一个数字，比如X版本，X+1版本。
而3.2属于标准版本，标准版本会为客户提供6个月的全支持（一般，严重和安全的问题的解决）直到下一个稳定版本发布，还会提供附加一个月的限制性支持（只包括严重和安全问题的解决）。标准版本会改变版本号的第二个数字，比如：X.4、X.6版本。
**基于业务稳定性考虑，采用LTS版本更为稳妥，**同时3.0 LTS相对于2.2 LTS在WEB界面与中文支持以及其他一些重要功能上做了很大的提升，因此我们选择3.0 LTS版本。
zabbix的web管理界面需要php+MySQL环境支持，在此我们选择LNMP环境。
zabbix的web页面安装路径：/home/zabbix
zabbix服务安装路径：/usr/local/zabbix
MySQL安装路径：/home/mysql

**2.2 下载软件包**
------
```
# wget http://sourceforge.net/projects/zabbix/files/ZABBIX%20Latest%20Stable/3.0.8/zabbix-3.0.8.tar.gz
# ls
zabbix-3.0.8.tar.gz

```
**2.3 创建相关安装目录**
------
```
# mkdir -pv /home/{zabbix,mysql}
mkdir: created directory `/home/zabbix'
mkdir: created directory `/home/mysql'
# tree /home/
/home/
├── mysql
│   └── data
├── soft
│   └── zabbix-3.0.8.tar.gz
└── zabbix

# mkdir /usr/local/zabbix/log
```

**3. 安装配置LNMP环境**
======
> 因为zabbix的web管理需要php环境支持，所以先配置LNMP环境，配置过程参考前文，此处不再赘述。

```
php编译参数
# ./configure --prefix=/usr/local/php --with-config-file-path=/usr/local/php/etc --with-fpm-user=www --with-fpm-group=www --enable-mysqlnd --with-mysqli=mysqlnd --with-pdo-mysql=mysqlnd --enable-ftp --enable-zip --with-bz2 --with-jpeg-dir --with-png-dir --with-freetype-dir --with-libxml-dir --with-xmlrpc --with-zlib-dir --with-gd --enable-gd-native-ttf --with-curl --enable-mbstring --enable-bcmath --enable-sockets --enable-exif --enable-fpm --with-mcrypt --with-mhash --with-gmp --enable-inline-optimization --with-openssl --with-pcre-dir --enable-soap --with-gettext

如果不加--with-gettext参数，zabbix将无法切换语言。
```
```
MySQL编译参数
# cmake -DCMAKE_INSTALL_PREFIX=/home/mysql  -DMYSQL_UNIX_ADDR=/tmp/mysql.sock  -DDEFAULT_CHARSET=utf8  -DDEFAULT_COLLATION=utf8_general_ci  -DWITH_MYISAM_STORAGE_ENGINE=1  -DWITH_INNOBASE_STORAGE_ENGINE=1  -DWITH_MEMORY_STORAGE_ENGINE=1  -DWITH_READLINE=1  -DENABLED_LOCAL_INFILE=1  -DMYSQL_DATADIR=/home/mysql/data  -DMYSQL_USER=mysql  -DMYSQL_TCP_PORT=3406 -DWITH_BOOST=/usr/local/boost
```

**程序包如下：**
```
# tree
.
├── mysql-5.7.15.tar.gz
├── openresty
│   ├── drizzle7-2011.07.21.tar.gz
│   ├── openresty-1.11.2.1.tar.gz
│   ├── openssl-1.0.2j.tar.gz
│   ├── pcre-8.38.tar.gz
│   └── zlib-1.2.8.tar.gz
└── zabbix-3.0.8.tar.gz
```
**4. 编译安装zabbix**
======
**4.1 创建zabbix服务用户**
------
```
# groupadd zabbix
# useradd zabbix -g zabbix -s /sbin/nologin
```

**4.2 安装依赖包**
------
```
# yum install -y net-snmp-devel curl-devel unixODBC-devel OpenIPMI-devel java-devel libssh2-devel openldap-devel
```
**4.3 编译前配置**
------
```
# pwd
/home/soft/zabbix-3.0.8
# ./configure --prefix=/usr/local/zabbix --enable-server --enable-agent --enable-ipv6 --with-mysql --with-net-snmp --with-libcurl -with-openipmi --with-unixodbc --with-ldap --with-ssh2 --with-iconv --enable-java
```
**4.4 编译安装zabbix**
------
```
# make && make install
# chown -R zabbix.zabbix /usr/local/zabbix/
```
**4.5 为zabbix提供启动脚本**
------
```
# cp misc/init.d/fedora/core/zabbix_* /etc/init.d/
# chmod +x /etc/init.d/zabbix_*
# sed -i 's@BASEDIR=/usr/local@BASEDIR=/usr/local/zabbix@g' /etc/init.d/zabbix_agentd
# sed -i 's@BASEDIR=/usr/local@BASEDIR=/usr/local/zabbix@g' /etc/init.d/zabbix_server
# chkconfig zabbix_server on
# chkconfig zabbix_agentd on
```
**4.6 创建zabbix数据库并导入数据**
------
```
mysql> create database zabbix character set utf8;
Query OK, 1 row affected (0.00 sec)

mysql> grant all privileges on zabbix.* to zabbix@localhost identified by 'zabbix';
Query OK, 0 rows affected, 2 warnings (0.01 sec)

mysql> flush privileges;

# mysql -uzabbix -pzabbix zabbix
测试新建数据库访问正常。

# mysql -uzabbix -pzabbix zabbix < ./database/mysql/schema.sql
# mysql -uzabbix -pzabbix zabbix < ./database/mysql/images.sql 
# mysql -uzabbix -pzabbix zabbix < ./database/mysql/data.sql

```
**4.7 修改zabbix配置文件**
------
```
# 
# vim /usr/local/zabbix/etc/zabbix_server.conf
ListenPort=10051
LogFile=/usr/local/zabbix/log/zabbix_server.log
LogFileSize=1
DebugLevel=3
PidFile=/usr/local/zabbix/log/zabbix_server.pid
DBHost=localhost
DBName=zabbix
DBUser=zabbix
DBPassword=zabbix
DBSocket=/home/mysql/tmp/mysql.sock
DBPort=3406
ListenIP=0.0.0.0
Timeout=4
LogSlowQueries=3000

# vim /usr/local/zabbix/etc/zabbix_agentd.conf
PidFile=/usr/local/zabbix/log/zabbix_agentd.pid
LogType=file
LogFile=/usr/local/zabbix/log/zabbix_agentd.log
LogFileSize=1
DebugLevel=3
Server=127.0.0.1
ListenPort=10050
ListenIP=0.0.0.0
ServerActive=127.0.0.1
Hostname=Zabbix server
```

**4.8 启动zabbix-server、zabbix-agentd服务**
------
**启动服务**
```
# service zabbix_server start
```
**如启动报错**
```
Starting zabbix_server:  /usr/local/zabbix/sbin/zabbix_server: error while loading shared libraries: libmysqlclient.so.20: cannot open shared object file: No such file or directory
                                                           [FAILED]
```
**检查是否库文件不存在**
```
# ldd $(which /usr/local/zabbix/sbin/zabbix_server)
```
**确有一条**
```
	libmysqlclient.so.20 => not found
```
**解决办法**
```
# vim /etc/ld.so.conf.d/mysql.conf
/home/mysql/lib
# ldconfig
```
**再次启动服务**
```
# service zabbix_server start
# service zabbix_agentd start
```

**5. 安装配置zabbix WEB前端**
======
**5.1 安装前相关配置**
------
```
# vim /etc/php.ini     （此处的php.ini以服务器上实际位置为准）
memory_limit = 128M
post_max_size = 16M
upload_max_filesize = 2M
max_execution_time = 300
max_input_time = 300
session.auto_start = 0
mbstring.func_overload = 0
always_populate_raw_post_data = -1
date.timezone = Asia/Shanghai
```
**5.2 准备WEB前端文件**
------
```
# pwd 
/home/soft/zabbix-3.0.8
# cp -r frontends/php/* /home/zabbix-web/
# chown -R www.www /home/zabbix-web/
```
**5.3 配置nginx相关zabbix网站配置**
------
```
# vim /usr/local/openresty/nginx/conf/nginx.conf
    server {
        listen       80;
        server_name  localhost;
        charset utf-8;
        location / {
            root   /home/zabbix;
            index  index.php index.html index.htm;
        }
        error_page   500 502 503 504  /50x.html;
        location = /50x.html {
            root   html;
        }

        location ~ \.php$ {
            root           /home/zabbix;
            fastcgi_pass   127.0.0.1:9000;
            fastcgi_index  index.php;
            fastcgi_param  SCRIPT_FILENAME  /scripts$fastcgi_script_name;
            #include        fastcgi_params;
            include        fastcgi.conf;
        }

    }
```
**5.4 访问WEB页面配置zabbix web**
------
```
http://IP
```
**5.5 解决zabbix web界面部分中文乱码的问题**
------
zabbix web安装完成后，**默认的中文支持并不完善**，在部分页面仍会出现中文支持不完全的问题，原因在于zabbix程序保重**默认的字体文件DejaVuSans.ttf对中文支持不完善**，所以需要我们**自行上传中文字体并修改配置文件**。
具体操作如下：
```
在这里我采用的是微软雅黑字体，首先将微软字体库中的雅黑字体文件上传至zabbix服务器/home/zabbix-web/fonts/目录

# ls /home/zabbix-web/fonts/
DejaVuSans.ttf  msyh.ttf

然后修改相应配置文件：
# pwd
/home/zabbix-web/include
# vim +45 defines.inc.php
define('ZBX_GRAPH_FONT_NAME',           'msyh'); // font file name
第45行，将字体文件名更改为你上传的字体文件名，我这里用的是"msyh"

# vim +93 defines.inc.php
define('ZBX_FONT_NAME', 'msyh');
第93行，同45行一致，修改字体文件名。
```
修改完成后，重新刷新页面，中文显示就正常了。

