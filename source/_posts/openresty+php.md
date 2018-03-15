---
title: 编译安装openresty+php
date: 2016-08-25
categories: 
 - Linux
 - Nginx/OpenResty
 - PHP

tags: 
 - 编译安装
 - openresty
 - php

---

 **1. 编译安装openresty**
 准备相关软件包
```shell
# wget https://openresty.org/download/openresty-1.11.2.1.tar.gz
# wget -P /root/soft/ ftp://ftp.csx.cam.ac.uk/pub/software/programming/pcre/pcre-8.38.tar.gz
# wget -P /root/soft/ https://nchc.dl.sourceforge.net/project/libpng/zlib/1.2.8/zlib-1.2.8.tar.gz
# wget -P /root/soft/ https://openresty.org/download/drizzle7-2011.07.21.tar.gz
# wget -P /root/soft/ https://www.openssl.org/source/openssl-1.0.2j.tar.gz
```
 解决依赖关系
```shell
 # yum install -y gcc gcc-c++ perl-devel perl-ExtUtils-Embed openssl-devel postgresql-devel libxml2-devel libxslt-devel gd-devel GeoIP-devel
```
 如果启用了--with-http_drizzle_module参数，则需要如下配置
```shell
# tar xzvf drizzle7-2011.07.21.tar.gz
# cd drizzle7-2011.07.21/
# ./configure --without-server
# make libdrizzle-1.0
# make install-libdrizzle-1.0
```

<!-- more -->

创建openresty运行用户
```shell
# groupadd www
# useradd www -g www -s /sbin/nologin
```
 编译前配置
```shell
# ./configure --user=www --group=www --with-http_iconv_module --with-http_drizzle_module --with-http_postgres_module --with-threads --with-file-aio --with-ipv6 --with-http_realip_module --with-http_addition_module --with-http_xslt_module --with-http_image_filter_module --with-http_geoip_module --with-http_sub_module --with-http_dav_module --with-http_flv_module --with-http_gzip_static_module --with-http_auth_request_module --with-http_random_index_module --with-http_secure_link_module --with-http_stub_status_module --with-http_perl_module --with-http_ssl_module --with-zlib=/root/soft/zlib-1.2.8 --with-pcre=/root/soft/pcre-8.38 --with-openssl=/root/soft/openssl-1.0.2j
```
编译配置过程中如果出现如下错误
> src/event/ngx_event_openssl.c: In function ‘ngx_ssl_connection_error’:
src/event/ngx_event_openssl.c:2048: error: ‘SSL_R_NO_CIPHERS_PASSED’ undeclared (first use in this function)
src/event/ngx_event_openssl.c:2048: error: (Each undeclared identifier is reported only once
src/event/ngx_event_openssl.c:2048: error: for each function it appears in.)
gmake[2]: \*\*\* [objs/src/event/ngx_event_openssl.o] Error 1
gmake[2]: Leaving directory \`/root/soft/openresty-1.11.2.1/build/nginx-1.11.2'
gmake[1]: \*\*\* [build] Error 2
gmake[1]: Leaving directory \`/root/soft/openresty-1.11.2.1/build/nginx-1.11.2'
gmake: \*\*\* [all] Error 2
**主要原因是因为**
The OpenSSL API has changed quite a bit in 1.1.0... this means that nginx needs some work to adapt.
openssl 1.1.0改变了太多，nginx暂时还不支持，版本换回1.0.x就行了。

编译安装
```shell
# gmake && gmake install
```
为openresty提供启动脚本
```shell
# vim /etc/init.d/nginx

#!/bin/sh
#
# nginx - this script starts and stops the nginx daemon
#
# chkconfig:   - 85 15 
# description:  Nginx is an HTTP(S) server, HTTP(S) reverse \
#               proxy and IMAP/POP3 proxy server
# processname: nginx
# config:      /usr/local/openresty/nginx/conf/nginx.conf
# pidfile:     /usr/local/openresty/nginx/logs/nginx.pid
 
# Source function library.
. /etc/rc.d/init.d/functions
 
# Source networking configuration.
. /etc/sysconfig/network
 
# Check that networking is up.
[ "$NETWORKING" = "no" ] && exit 0
 
nginx="/usr/local/openresty/nginx/sbin/nginx"
prog=$(basename $nginx)
 
NGINX_CONF_FILE="/usr/local/openresty/nginx/conf/nginx.conf"
 
[ -f /etc/sysconfig/nginx ] && . /etc/sysconfig/nginx
 
lockfile=/var/lock/subsys/nginx
 
make_dirs() {
   # make required directories
   user=`$nginx -V 2>&1 | grep "configure arguments:" | sed 's/[^*]*--user=\([^ ]*\).*/\1/g' -`
   if [ -z "`grep $user /etc/passwd`" ]; then
       useradd -M -s /bin/nologin $user
   fi
   options=`$nginx -V 2>&1 | grep 'configure arguments:'`
   for opt in $options; do
       if [ `echo $opt | grep '.*-temp-path'` ]; then
           value=`echo $opt | cut -d "=" -f 2`
           if [ ! -d "$value" ]; then
               # echo "creating" $value
               mkdir -p $value && chown -R $user $value
           fi
       fi
   done
}
 
start() {
    [ -x $nginx ] || exit 5
    [ -f $NGINX_CONF_FILE ] || exit 6
    make_dirs
    echo -n $"Starting $prog: "
    daemon $nginx -c $NGINX_CONF_FILE
    retval=$?
    echo
    [ $retval -eq 0 ] && touch $lockfile
    return $retval
}
 
stop() {
    echo -n $"Stopping $prog: "
    killproc $prog -QUIT
    retval=$?
    echo
    [ $retval -eq 0 ] && rm -f $lockfile
    return $retval
}
 
restart() {
    configtest || return $?
    stop
    sleep 3 
    start
}
 
reload() {
    configtest || return $?
    echo -n $"Reloading $prog: "
    killproc $nginx -HUP
    RETVAL=$?
    echo
}
 
force_reload() {
    restart
}
 
configtest() {
  $nginx -t -c $NGINX_CONF_FILE
}
 
rh_status() {
    status $prog
}
 
rh_status_q() {
    rh_status >/dev/null 2>&1
}
 
case "$1" in
    start)
        rh_status_q && exit 0
        $1
        ;;
    stop)
        rh_status_q || exit 0
        $1
        ;;
    restart|configtest)
        $1
        ;;
    reload)
        rh_status_q || exit 7
        $1
        ;;
    force-reload)
        force_reload
        ;;
    status)
        rh_status
        ;;
    condrestart|try-restart)
        rh_status_q || exit 0
            ;;
    *)
        echo $"Usage: $0 {start|stop|status|restart|condrestart|try-restart|reload|force-reload|configtest}"
        exit 2
esac

# chmod +x /etc/init.d/nginx
# chkconfig --add nginx
# chkconfig nginx on
```
启动服务
```shell
# service nginx start
```
如果启动时报错：
```shell
# /usr/local/openresty/nginx/sbin/nginx 
/usr/local/openresty/nginx/sbin/nginx: error while loading shared libraries: libdrizzle.so.1: cannot open shared object file: No such file or directory
```
检查是否库文件不存在
```shell
# ldd $(which /usr/local/openresty/nginx/sbin/nginx)
```
结果发现确实
```shell
libdrizzle.so.1 => not found
```
检查/usr/local/{lib|lib64}目录下是否存在库文件，如果存在，则说明系统并没有加载库文件，我们需要手动指定系统加载。
在/etc/ld.so.conf.d/目录下新建任何以.conf为后缀的文件，在该文件中加入库文件所在的目录。
```shell
# vim /etc/ld.so.conf.d/openresty.conf
/usr/local/lib
/usr/local/lib64
```
然后执行ldconfig更新/etc/ld.so.cache文件，解决问题。

如果需要隐藏openresty/nginx版本，只需要编辑nginx.conf，在http配置中添加以下配置即可解决。
```shell
server_tokens off;
```
 
 **2. 编译安装php**
 解决依赖关系
```shell
# yum install -y libxml2-devel bzip2-devel libcurl-devel gd-devel gmp-devel libmcrypt-devel
```
创建php安装位置
```shell
# mkdir /usr/local/php
```
创建php-fpm运行用户
```shell
# groupadd www
# useradd www -g www -s /sbin/nologin
```
编译前配置
```shell
# ./configure --prefix=/usr/local/php --with-config-file-path=/usr/local/php/etc --with-fpm-user=www --with-fpm-group=www --enable-mysqlnd --with-mysqli=mysqlnd --with-pdo-mysql=mysqlnd --enable-ftp --enable-zip --with-bz2 --with-jpeg-dir --with-png-dir --with-freetype-dir --with-libxml-dir --with-xmlrpc --with-zlib-dir --with-gd --enable-gd-native-ttf --with-curl --enable-mbstring --enable-bcmath --enable-sockets --enable-exif --enable-fpm --with-mcrypt --with-mhash --with-gmp --enable-inline-optimization --with-openssl --with-pcre-dir --enable-soap --with-gettext
```
编译安装
```shell
# make && make install
```
为php提供配置文件
```shell
# cp php.ini-production /usr/local/php/etc/php.ini
```
为php-fpm提供Sysv脚本并添加至服务列表设置开机启动
```shell
# cp sapi/fpm/init.d.php-fpm /etc/init.d/php-fpm
# chmod +x /etc/init.d/php-fpm
# chkconfig --add php-fpm
# chkconfig php-fpm on
```
为php-fpm提供配置文件
```shell
# cp /usr/local/php/etc/php-fpm.conf.default /usr/local/php/etc/php-fpm.conf
```
编辑php-fpm配置文件，按需修改配置
```shell
# vim /usr/local/php/etc/php-fpm.conf
```
启动php-fpm
```shell
# service php-fpm start
```

 **3. 配置openresty支持php**
修改nginx配置文件，启用php支持
```shell
# vim /usr/local/openresty/nginx/conf/nginx.conf
 
 启用下述配置
         location ~ \.php$ {
            root           html;
            fastcgi_pass   127.0.0.1:9000;
            fastcgi_index  index.php;
            fastcgi_param  SCRIPT_FILENAME  /scripts$fastcgi_script_name;
            include        fastcgi.conf;
        }

```
