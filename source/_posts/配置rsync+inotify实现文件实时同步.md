---
title: 配置rsync+inotify实现文件实时同步
date: 2018-06-04
categories: 
 - Linux
 - Centos
 - rsync

tags: 
 - rsync
 - inotify
 - 文件同步
  
---

**1. 项目背景**
======
> 因为工作需要，需部署一套nginx负载均衡群集，群集须保证所有nginx节点配置文件完全一致；要解决不同服务器之间数据一致，一般采用NFS共享文件、DRBD镜像复制或rsync文件同步来实现，相对于rsync，前两者配置稍麻烦，此处我选择rsync文件同步来保证配置文件一致性。

> rsync是一个远程数据同步工具，可通过LAN/WAN快速同步多台主机间的文件。它使用所谓的“Rsync演算法”来使本地和远程两个主机之间的文件达到同步，这个算法只传送两个文件的不同部分，而不是每次都整份传送，因此速度相当快。但是rsync仅仅是同步工具，并不能做到监控文件变化并实时同步，因此还需要配合inotify来实现文件实时同步。

> inotify是一种强大的、细粒度的、异步的文件系统事件控制机制。linux内核从2.6.13起，加入了inotify支持，通过inotify可以监控文件系统中添加、删除、修改、移动等各种事件，利用这个内核接口，第三方软件就可以监控文件系统下文件的各种变化情况，而inotify-tools正是实施监控的软件。

> 在这里，我们使用inotify监控文件变化，同时通过脚本来触发rsync将发生变化的文件同步到目标服务器。

> **术语定义：**
客户端-->源服务器（SRC）
服务端-->目标服务器（DEST）

<!-- more -->

**2. 安装配置rsync**
======
2.1 安装rsync服务
------
```shell
# yum install -y gcc gcc-c++
# yum install -y rsync
关闭SELINUX（服务端SELINUX一定要关掉，不然rsync同步的时候会报错）
# setenforce 0
# vim /etc/selinux/config
SELINUX=disabled
```
2.2 编辑rsync配置文件
------
```shell
# vim /etc/rsyncd.conf

uid = root     # 此处的用户及用户组必须要拥有操作待同步文件的权限
gid = root
port = 873     # rsync默认监听端口873，也可以自定义
use chroot = no  
max connections = 5
pid file = /var/run/rsyncd.pid
exclude = lost+found/   # 排除同步文件
transfer logging = yes
timeout = 900
ignore nonreadable = yes
dont compress   = *.gz *.tgz *.zip *.z *.Z *.rpm *.deb *.bz2

[nginx_conf]
path = /data/program/nginx/conf/    # rsync服务端数据目录路径，即同步到目标目录后的存放路径，按需配置
comment = nginx_conf  # 此处定义模块名称，这个模块名称在rsync同步命令中需要调用
ignore errors
read only = no
list = yes
auth users = rsync    # 设置执行rsync同步的用户名，此用户名可自定义，不需与系统用户一致，需要与secrets file中设置的用户名匹配
secrets file = /data/program/rsync/rsync_server.passwd  # 用户认证配置文件，保存同步时使用的用户名密码，可设置多个用户名密码
hosts allow = 192.168.2.182  #允许进行同步的客户端地址，可设置多个，用英文逗号分隔
```
2.3 编辑rsync用户认证配置文件
------
```shell
服务端
# vim /data/program/rsync/rsync_server.passwd
rsync:rsync

客户端
# vim /data/program/rsync/rsync_client.passwd
rsync

双向同步的时候，两台服务器上都需要配置这两个文件。
```
2.4 修改配置文件权限
------
```shell
# chmod 600 /data/program/rsync/rsync_server.passwd
# chmod 600 /data/program/rsync/rsync_client.passwd
# chmod 600 /etc/rsyncd.conf
```
2.5 启动rsync服务
------
```shell
# systemctl enable rsyncd
# systemctl start rsyncd
```
2.6 双向同步配置
------
单向同步
```shell
如果仅需单向同步，只需要在服务端启动rsyncd服务，客户端无需启动服务，可直接执行rsync命令。
```
双向同步
```shell
如需双向同步，则需要在两台服务器启动rsyncd服务，两台服务器互为C-->S。
```
此处我选择双向同步，则需在两台服务器上同时配置服务。

**3. 安装配置inotify-tools**
======
```shell
# yum install -y inotify-tools
```

**4. 配置inotify_rsync同步脚本**
======
```shell
# cd /data/program/rsync/
# vim inotify_rsync.sh

#!/bin/bash
source /etc/profile

src=/data/program/nginx/conf              # 需要同步的源路径
des=nginx_conf                            # 目标服务器上rsyncd.conf中定义的名称(comment)
rsync_passwd_file=/data/program/rsync/rsync_client.passwd            # rsync验证的密码文件
ip=192.168.2.182                          # 目标服务器
user=rsync                                # rsyncd.conf中定义的验证用户名(auth users)
include_list=/data/program/rsync/include  #指定同步文件写入列表文件，列表文件路径必须用绝对路径，列表文件中内容用相对路径
log_path=/data/program/rsync/logs/$(date +%Y-%m-%d).log    #同步日志输出到日志文件

cd ${src}
inotifywait -mrq --format  '%Xe %w%f' -e modify,create,delete,attrib,close_write,move ./ | while read file
do
        INO_EVENT=$(echo $file | awk '{print $1}')      # 把inotify输出切割 把事件类型部分赋值给INO_EVENT
        INO_FILE=$(echo $file | awk '{print $2}')       # 把inotify输出切割 把文件路径部分赋值给INO_FILE
        echo "-------------------------------$(date)------------------------------------"  >> ${log_path}
        echo $file  >> ${log_path}
        #增加、修改、写入完成、移动进事件
        #增、改放在同一个判断，因为他们都是针对文件的操作，即使是新建目录，要同步的也只是一个空目录，不会影响速度。
        if [[ $INO_EVENT =~ 'CREATE' ]] || [[ $INO_EVENT =~ 'MODIFY' ]] || [[ $INO_EVENT =~ 'CLOSE_WRITE' ]] || [[ $INO_EVENT =~ 'MOVED_TO' ]]         # 判断事件类型
        then
                echo 'CREATE or MODIFY or CLOSE_WRITE or MOVED_TO'  >> ${log_path}
                rsync -avrtzopgcRP --include-from=${include_list} --exclude=/* --password-file=${rsync_passwd_file} $(dirname ${INO_FILE}) ${user}@${ip}::${des}  >> ${log_path}
        fi
        #删除、移动出事件
        if [[ $INO_EVENT =~ 'DELETE' ]] || [[ $INO_EVENT =~ 'MOVED_FROM' ]]
        then
                echo 'DELETE or MOVED_FROM'  >> ${log_path}
                rsync -avrtzopgcRP --delete --include-from=${include_list} --exclude=/* --password-file=${rsync_passwd_file} $(dirname ${INO_FILE}) ${user}@${ip}::${des}  >> ${log_path}
        fi
        #修改属性事件 指 touch chgrp chmod chown等操作
        if [[ $INO_EVENT =~ 'ATTRIB' ]]
        then
                echo 'ATTRIB'  >> ${log_path}
                if [ ! -d "$INO_FILE" ]
                # 如果修改属性的是目录 则不同步，因为同步目录会发生递归扫描，等此目录下的文件发生同步时，rsync会顺带更新此目录。
                then
                        rsync -avrtzopgcRP --include-from=${include_list} --exclude=/* --password-file=${rsync_passwd_file} $(dirname ${INO_FILE}) ${user}@${ip}::${des}  >> ${log_path}
                fi
        fi
done
```
编辑指定同步文件列表
```shell
# vim /data/program/rsync/include
nginx.conf
nginx_conf/
conf.d/

将指定同步的文件写到该列表文件中，需使用相对路径
```
给同步脚本添加执行权限
```shell
# chmod +x inotify_rsync.sh
```

**5. 将同步脚本放到后台启动**
======
```shell
# nohup /data/program/rsync/inotify_rsync.sh >/data/program/rsync/nohup.out 2>&1 &
```

**6. 将同步脚本加到开机启动**
======
```shell
# echo "nohup /data/program/rsync/inotify_rsync.sh >/data/program/rsync/nohup.out 2>&1 &" >> /etc/rc.local
```

**7. rsync+inotifywait部分参数说明**
======
7.1 rsync参数说明
------
```shell
-v, --verbose 详细模式输出
-q, --quiet 精简输出模式
-c, --checksum 打开校验开关，强制对文件传输进行校验
-a, --archive 归档模式，表示以递归方式传输文件，并保持所有文件属性，等于-rlptgoD
-r, --recursive 对子目录以递归模式处理
-R, --relative 使用相对路径信息
-b, --backup 创建备份，也就是对于目的已经存在有同样的文件名时，将老的文件重新命名为~filename。可以使用--suffix选项来指定不同的备份文件前缀。
--backup-dir 将备份文件(如~filename)存放在在目录下。
-suffix=SUFFIX 定义备份文件前缀
-u, --update 仅仅进行更新，也就是跳过所有已经存在于DST，并且文件时间晚于要备份的文件。(不覆盖更新的文件)
-l, --links 保留软链结
-L, --copy-links 想对待常规文件一样处理软链结
--copy-unsafe-links 仅仅拷贝指向SRC路径目录树以外的链结
--safe-links 忽略指向SRC路径目录树以外的链结
-H, --hard-links 保留硬链结
-p, --perms 保持文件权限
-o, --owner 保持文件属主信息
-g, --group 保持文件属组信息
-D, --devices 保持设备文件信息
-t, --times 保持文件时间信息
-S, --sparse 对稀疏文件进行特殊处理以节省DST的空间
-n, --dry-run现实哪些文件将被传输
-W, --whole-file 拷贝文件，不进行增量检测
-x, --one-file-system 不要跨越文件系统边界
-B, --block-size=SIZE 检验算法使用的块尺寸，默认是700字节
-e, --rsh=COMMAND 指定使用rsh、ssh方式进行数据同步
--rsync-path=PATH 指定远程服务器上的rsync命令所在路径信息
-C, --cvs-exclude 使用和CVS一样的方法自动忽略文件，用来排除那些不希望传输的文件
--existing 仅仅更新那些已经存在于DST的文件，而不备份那些新创建的文件
--delete 删除那些DST中SRC没有的文件
--delete-excluded 同样删除接收端那些被该选项指定排除的文件
--delete-after 传输结束以后再删除
--ignore-errors 及时出现IO错误也进行删除
--max-delete=NUM 最多删除NUM个文件
--partial 保留那些因故没有完全传输的文件，以是加快随后的再次传输
--force 强制删除目录，即使不为空
--numeric-ids 不将数字的用户和组ID匹配为用户名和组名
--timeout=TIME IP超时时间，单位为秒
-I, --ignore-times 不跳过那些有同样的时间和长度的文件
--size-only 当决定是否要备份文件时，仅仅察看文件大小而不考虑文件时间
--modify-window=NUM 决定文件是否时间相同时使用的时间戳窗口，默认为0
-T --temp-dir=DIR 在DIR中创建临时文件
--compare-dest=DIR 同样比较DIR中的文件来决定是否需要备份
-P 等同于 --partial
--progress 显示备份过程
-z, --compress 对备份的文件在传输时进行压缩处理
--exclude=PATTERN 指定排除不需要传输的文件模式
--include=PATTERN 指定不排除而需要传输的文件模式
--exclude-from=FILE 排除FILE中指定模式的文件
--include-from=FILE 不排除FILE指定模式匹配的文件
--version 打印版本信息
--address 绑定到特定的地址
--config=FILE 指定其他的配置文件，不使用默认的rsyncd.conf文件
--port=PORT 指定其他的rsync服务端口
--blocking-io 对远程shell使用阻塞IO
-stats 给出某些文件的传输状态
--progress 在传输时现实传输过程
--log-format=formAT 指定日志文件格式
--password-file=FILE 从FILE中得到密码
--bwlimit=KBPS 限制I/O带宽，KBytes per second
-h, --help 显示帮助信息
```
7.2 inotifywait参数说明
------
```shell
-h,–help 输出帮助信息
-m,–monitor	始终保持事件监听状态，接收到一个事件而不退出，无限期地执行。默认的行为是接收到一个事件后立即退出
-r,–recursive 递归查询目录
-q,–quiet	只打印监控事件的信息
–exclude	正则匹配需要排除的文件，区分大小写
–excludei	正则匹配需要排除的文件，不区分大小写
-t,–timeout	超时时间，如果为0，则无限期地执行下去
–timefmt	指定时间输出格式，用于–format选项中的%T格式
–format	指定输出格式
	%w 表示发生事件的目录
	%f 表示发生事件的文件
	%e 表示发生的事件
	%Xe 事件以“X”分隔
	%T 使用由–timefmt定义的时间格式
-e,–event 指定监视的事件
–fromfile 从文件读取需要监视的文件或排除的文件，一个文件一行，排除的文件以@开头
-d, –daemon 跟–monitor一样，除了是在后台运行，需要指定–outfile把事情输出到一个文件。也意味着使用了–syslog。
-o, –outfile  输出事情到一个文件而不是标准输出。
-s, –syslog 输出错误信息到系统日志
-c, –csv 输出csv格式

```
7.3 inotifywait events事件说明
------
```shell
access	读取文件或目录内容
modify	修改文件或目录内容
attrib	文件或目录属性更改，如权限，时间戳等
close_write	以可写模式打开的文件被关闭，不代表此文件一定已经写入数据
close_nowrite	以只读模式打开的文件被关闭
close	文件被关闭，不管它是如何打开的
open	文件打开
moved_to	一个文件或目录移动到监听的目录，即使是在同一目录内移动，此事件也触发
moved_from	一个文件或目录移出监听的目录，即使是在同一目录内移动，此事件也触发
move	包括moved_to和 moved_from
move_self	文件或目录被移除，之后不再监听此文件或目录
create	文件或目录创建
delete	文件或目录删除
delete_self	文件或目录移除，之后不再监听此文件或目录
unmount	文件系统取消挂载，之后不再监听此文件系统
```








