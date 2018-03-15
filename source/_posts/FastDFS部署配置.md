---
title: FastDFS部署配置
date: 2017-01-24
categories: 
 - Linux
 - FastDFS

tags: 
 - FastDFS

---

**1. 安装FastDFS服务**
========
**所需软件包**
--------
> fastdfs-nginx-module_v1.16.tar.gz
FastDFS_v5.05.tar.gz
libfastcommon
ngx_cache_purge-2.3.tar.gz

**安装软件依赖环境**
--------
```
# yum install -y libevent gcc* git
```
**安装 libfastcommon**
--------
```
从github下载最新的libfastcommon
# git clone https://github.com/happyfish100/libfastcommon.git
# cd libfastcommon
编译
# ./make.sh
安装
# ./make.sh install
指定库文件加载位置
# vim /etc/ld.so.conf.d/libfastcommon.conf
/usr/local/lib
/usr/local/lib64
/usr/lib64
/usr/lib
然后执行ldconfig更新/etc/ld.so.cache文件
# ldconfig
```
**安装FastDFS**
--------
```
# tar zxf FastDFS_v5.05.tar.gz
# cd FastDFS/
# ./make.sh
# ./make.sh install
确认make没有错误后，执行安装，默认会安装到/usr/bin中，并在/etc/fdfs中添加三个配置文件。
```
**创建文件存放路径**
--------
```
# mkdir -p /home/fastdfs/tracker   #创建tracker文件存放路径
# mkdir -p /home/fastdfs/storage    #创建storage 文件存放路径
# mkdir -p /home/fastdfs/client    #创建client 文件存放路径

# mkdir -pv /home/fastdfs/{tracker,storage,client}
```
**修改配置文件**
--------
```
# cd /etc/fdfs/
# ls
client.conf.sample  storage.conf.sample  tracker.conf.sample
# cp client.conf.sample client.conf
# cp storage.conf.sample storage.conf
# cp tracker.conf.sample tracker.conf

# vim tracker.conf
disabled=false
bind_addr=
port=22122
connect_timeout=30
network_timeout=60
base_path=/home/fastdfs/tracker
max_connections=256
accept_threads=1
work_threads=4
store_lookup=2
store_group=group2
store_server=0
store_path=0
download_server=0
reserved_storage_space = 10%
log_level=info
run_by_group=
run_by_user=
allow_hosts=*
sync_log_buff_interval = 10
check_active_interval = 120
thread_stack_size = 64KB
storage_ip_changed_auto_adjust = true
storage_sync_file_max_delay = 86400
storage_sync_file_max_time = 300
use_trunk_file = false 
slot_min_size = 256
slot_max_size = 16MB
trunk_file_size = 64MB
trunk_create_file_advance = false
trunk_create_file_time_base = 02:00
trunk_create_file_interval = 86400
trunk_create_file_space_threshold = 20G
trunk_init_check_occupying = false
trunk_init_reload_from_binlog = false
trunk_compress_binlog_min_interval = 0
use_storage_id = false
storage_ids_filename = storage_ids.conf
id_type_in_filename = ip
store_slave_file_use_link = false
rotate_error_log = false
error_log_rotate_time=00:00
rotate_error_log_size = 0
log_file_keep_days = 0
use_connection_pool = false
connection_pool_max_idle_time = 3600
http.server_port=8080
http.check_alive_interval=30
http.check_alive_type=tcp
http.check_alive_uri=/status.html

# vim storage.conf
disabled=false
group_name=group1
bind_addr=
client_bind=true
port=23000
connect_timeout=30
network_timeout=60
heart_beat_interval=30
stat_report_interval=60
base_path=/home/fastdfs/storage
max_connections=256
buff_size = 256KB
accept_threads=1
work_threads=4
disk_rw_separated = true
disk_reader_threads = 1
disk_writer_threads = 1
sync_wait_msec=50
sync_interval=0
sync_start_time=00:00
sync_end_time=23:59
write_mark_file_freq=500
store_path_count=1
store_path0=/home/fastdfs/storage
subdir_count_per_path=256
tracker_server=10.1.1.150:22122
log_level=info
run_by_group=
run_by_user=
allow_hosts=*
file_distribute_path_mode=0
file_distribute_rotate_count=100
fsync_after_written_bytes=0
sync_log_buff_interval=10
sync_binlog_buff_interval=10
sync_stat_file_interval=300
thread_stack_size=512KB
upload_priority=10
if_alias_prefix=
check_file_duplicate=0
file_signature_method=hash
key_namespace=FastDFS
keep_alive=0
use_access_log = false
rotate_access_log = false
access_log_rotate_time=00:00
rotate_error_log = false
error_log_rotate_time=00:00
rotate_access_log_size = 0
rotate_error_log_size = 0
log_file_keep_days = 0
file_sync_skip_invalid_record=false
use_connection_pool = false
connection_pool_max_idle_time = 3600
http.domain_name=
http.server_port=8888

# vim client.conf
connect_timeout=30
network_timeout=60
base_path=/home/fastdfs/client
tracker_server=10.1.1.150:22122
log_level=info
use_connection_pool = false
connection_pool_max_idle_time = 3600
load_fdfs_parameters_from_tracker=false
use_storage_id = false
storage_ids_filename = storage_ids.conf
http.tracker_server_port=80
```
**启动tracker和storage服务**
--------
```
# /usr/bin/fdfs_trackerd /etc/fdfs/tracker.conf
# /usr/bin/fdfs_storaged /etc/fdfs/storage.conf
storage首次启动会很慢，因为它在创建预设存储文件的目录，默认创建256个数据存放目录。

检查服务是否启动正常
# netstat -nultp | grep fdfs
tcp        0      0 0.0.0.0:22122               0.0.0.0:*                   LISTEN      14633/fdfs_trackerd 
tcp        0      0 0.0.0.0:23000               0.0.0.0:*                   LISTEN      14643/fdfs_storaged
```
**使用自带的工具fdfs_test测试上传、删除文件**
--------
```
上传文件
# fdfs_test /etc/fdfs/client.conf upload install.log
This is FastDFS client test program v5.05

Copyright (C) 2008, Happy Fish / YuQing

FastDFS may be copied only under the terms of the GNU General
Public License V3, which may be found in the FastDFS source kit.
Please visit the FastDFS Home Page http://www.csource.org/ 
for more detail.

[2016-12-29 23:46:46] DEBUG - base_path=/home/fastdfs/client, connect_timeout=30, network_timeout=60, tracker_server_count=1, anti_steal_token=0, anti_steal_secret_key length=0, use_connection_pool=0, g_connection_pool_max_idle_time=3600s, use_storage_id=0, storage server id count: 0

tracker_query_storage_store_list_without_group: 
	server 1. group_name=, ip_addr=10.1.1.150, port=23000

group_name=group1, ip_addr=10.1.1.150, port=23000
storage_upload_by_filename
group_name=group1, remote_filename=M00/00/00/CgEBllhlL-aAJf9YAAAigwDiG9U128.log
source ip address: 10.1.1.150
file timestamp=2016-12-29 23:46:46
file size=8835
file crc32=14818261
example file url: http://10.1.1.150/group1/M00/00/00/CgEBllhlL-aAJf9YAAAigwDiG9U128.log
storage_upload_slave_by_filename
group_name=group1, remote_filename=M00/00/00/CgEBllhlL-aAJf9YAAAigwDiG9U128_big.log
source ip address: 10.1.1.150
file timestamp=2016-12-29 23:46:46
file size=8835
file crc32=14818261
example file url: http://10.1.1.150/group1/M00/00/00/CgEBllhlL-aAJf9YAAAigwDiG9U128_big.log
上面这个example file url现在还不能在浏览器中直接访问，因为必须要配合nginx使用才行。

我们看一下文件实际的物理存储位置。
# ls /home/fastdfs/storage/data/00/00/  
CgEBllhlL-aAJf9YAAAigwDiG9U128_big.log  CgEBllhlL-aAJf9YAAAigwDiG9U128_big.log-m  CgEBllhlL-aAJf9YAAAigwDiG9U128.log  CgEBllhlL-aAJf9YAAAigwDiG9U128.log-m

删除文件
# fdfs_test /etc/fdfs/client.conf delete install.log
This is FastDFS client test program v5.05

Copyright (C) 2008, Happy Fish / YuQing

FastDFS may be copied only under the terms of the GNU General
Public License V3, which may be found in the FastDFS source kit.
Please visit the FastDFS Home Page http://www.csource.org/ 
for more detail.

[2016-12-29 23:52:47] DEBUG - base_path=/home/fastdfs/client, connect_timeout=30, network_timeout=60, tracker_server_count=1, anti_steal_token=0, anti_steal_secret_key length=0, use_connection_pool=0, g_connection_pool_max_idle_time=3600s, use_storage_id=0, storage server id count: 0

Usage: fdfs_test <config_file> delete <group_name> <remote_filename>
删除的时候我们会发现报错了，因为删除文件必须要完整的group_name和remote_filename才可以。
从上面的上传信息中我们可以得知group_name=group1,remote_filename=M00/00/00/CgEBllhlL-aAJf9YAAAigwDiG9U128_big.log，所以正确的删除命令应该是：
# fdfs_test /etc/fdfs/client.conf delete group1 M00/00/00/CgEBllhlL-aAJf9YAAAigwDiG9U128.log

This is FastDFS client test program v5.05
Copyright (C) 2008, Happy Fish / YuQing

FastDFS may be copied only under the terms of the GNU General
Public License V3, which may be found in the FastDFS source kit.
Please visit the FastDFS Home Page http://www.csource.org/ 
for more detail.

[2016-12-29 23:59:32] DEBUG - base_path=/home/fastdfs/client, connect_timeout=30, network_timeout=60, tracker_server_count=1, anti_steal_token=0, anti_steal_secret_key length=0, use_connection_pool=0, g_connection_pool_max_idle_time=3600s, use_storage_id=0, storage server id count: 0

storage=10.1.1.150:23000
delete file success
删除成功。
再来检查物理存储位置
# ls /home/fastdfs/storage/data/00/00/ 
目录下为空

实际在上传时会在上传文件外另外生成一个文件名后加_big的文件，所以删除文件时应一并删除这两个文件。
```

**2. 安装nginx和nginx-fastdfs模块并配置**
========
**解压配置nginx-fastdfs**
--------
```
# tar zxf fastdfs-nginx-module_v1.16.tar.gz
# cd fastdfs-nginx-module/
编辑nginx模块的配置文件
# vim src/config
修改
CORE_INCS="$CORE_INCS /usr/local/include/fastdfs /usr/local/include/fastcommon/"
修改为
CORE_INCS="$CORE_INCS /usr/include/fastdfs /usr/include/fastcommon/"
因为实际上fastdfs的头文件在/usr/include/fastdfs与/usr/include/fastcommon/目录下

复制配置文件
# cp /root/soft/fastdfs/FastDFS/conf/http.conf /root/soft/fastdfs/FastDFS/conf/mime.types /etc/fdfs/
```
**安装nginx及nginx-fastdfs模块**
--------
```
解决依赖关系
# yum install -y gcc* pcre-devel zlib-devel openssl-devel
安装nginx
# tar zxf openresty-1.11.2.1.tar.gz
# cd openresty-1.11.2.1/
# ./configure  --with-http_gzip_static_module --add-module=/root/soft/fastdfs/fastdfs-nginx-module/src/
# gmake && gmake install
```
**编辑nginx-fastdfs模块配置文件**
--------
```
# cp /root/soft/fastdfs/fastdfs-nginx-module/src/mod_fastdfs.conf /etc/fdfs/
# vim /etc/fdfs/mod_fastdfs.conf
connect_timeout=2
network_timeout=30
base_path=/tmp
load_fdfs_parameters_from_tracker=true
storage_sync_file_max_delay = 86400
use_storage_id = false
storage_ids_filename = storage_ids.conf
tracker_server=10.1.1.150:22122
storage_server_port=23000
group_name=group1
url_have_group_name = true
store_path_count=1
store_path0=/home/fastdfs/storage
log_level=info
log_filename=
response_mode=proxy
if_alias_prefix=
flv_support = true
flv_extension = flv
group_count = 0
```
**编辑nginx配置文件**
--------
```
# vim /usr/local/openresty/nginx/conf/nginx.conf
user  root;
worker_processes  1;
events {
    worker_connections  1024;
}
http {
    include       mime.types;
    default_type  application/octet-stream;
    log_format  main  '$remote_addr - $remote_user [$time_local] "$request" '
                      '$status $body_bytes_sent "$http_referer" '
                      '"$http_user_agent" "$http_x_forwarded_for"';
    access_log  logs/access.log  main;
    sendfile        on;
    keepalive_timeout  60;
    gzip  on;
    server {
        listen       80;
        server_name  localhost;
        location ~/group([0-9])/M00 {
            ngx_fastdfs_module;
        }
        error_page   500 502 503 504  /50x.html;
        location = /50x.html {
            root   html;
        }
    }
}

```
**启动nginx服务**
--------
```
# /usr/local/openresty/nginx/sbin/nginx -t
# /usr/local/openresty/nginx/sbin/nginx
```
**上传文件并测试是否能正常访问**
--------
```
# fdfs_test /etc/fdfs/client.conf upload test.html
# curl -I http://10.1.1.150/group1/M00/00/00/CgEBlVhyVPSAM6m1AAAAhl47IRo71_big.html
HTTP/1.1 200 OK
```
**报错解决办法**
--------
如果访问时报400错误，查看错误日志：
```
[2017-01-09 22:57:06] ERROR - file: ../common/fdfs_global.c, line: 52, the format of filename "group1/M00/00/00/wKgBylhzpI2AW8AFAAAAE-vP9Cw582_big.txt" is invalid
```
解决办法
```
# vim /etc/fdfs/mod_fastdfs.conf
将url_have_group_name = false
修改为
url_have_group_name = true
```
