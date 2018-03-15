---
title: keepalived部署
date: 2016-12-10
categories: 
 - Linux
 - keepalived

tags: 
 - keepalived

---

**1. Director Server配置**
**安装软件依赖环境**
```
# yum install -y gcc*
# yum install -y openssl*
```
**安装ipvsadm**
```
# yum install -y ipvsadm
```
**下载软件安装包并解压**
```
# wget http://www.keepalived.org/software/keepalived-1.3.2.tar.gz
# tar zxf keepalived-1.3.2.tar.gz
```
**为程序准备安装目录**
```
# mkdir /usr/local/keepalived
# mkdir /etc/keepalived
```
**编译前配置**
```
# cd keepalived-1.3.2
# ./configure --prefix=/usr/local/keepalived/
```
**编译安装**
```
# make && make install
```
**为keepalived准备启动脚本和配置文件**
```
# cd /usr/local/keepalived/
# cp /usr/local/keepalived/sbin/keepalived /usr/sbin/
# cp /usr/local/keepalived/etc/sysconfig/keepalived /etc/sysconfig/
# cp /root/soft/keepalived-1.3.2/keepalived/etc/init.d/keepalived /etc/init.d/
```
**将keepalived加入开机启动项**
```
# chmod +x /etc/init.d/keepalived
# chkconfig --add keepalived
# chkconfig keepalived on
```
**在MASTER服务器上按需修改keepalived.conf配置文件**
```
# vim /etc/keepalived/keepalived.conf
! Configuration File for keepalived

global_defs {
    notification_email {
        wanglei@kuparts.com
    }
    notification_email_from admin@test.com
    smtp_server 127.0.0.1
    smtp_connect_timeout 30
    router_id LVS_MASTER
    vrrp_skip_check_adv_addr
    vrrp_strict
    vrrp_garp_interval 0
    vrrp_gna_interval 0
}

## for Nginx vrrp 实例配置
vrrp_instance VI_nginx {
    state MASTER
    interface em1     # 此处interface名称一定要跟服务器上实际的网卡名称一致，否则keepalived服务会启动失败。
    virtual_router_id 61
    priority 100
    advert_int 1
    authentication {
        auth_type PASS
        auth_pass 123456
    }
    virtual_ipaddress {
        121.201.40.140
    }
}

## for Nginx real_server相关配置
virtual_server 121.201.40.140 80 {
    delay_loop 6
    lb_algo rr
    lb_kind DR
    nat_mask 255.255.255.0
    persistence_timeout 50
    protocol TCP

    real_server 192.168.1.9 80 {
        weight 1
        TCP_CHECK {
            connect_timeout 3
            nb_get_retry 3
            delay_before_retry 3
        }
    }
    real_server 192.168.1.10 80 {
        weight 1
        TCP_CHECK {
            connect_timeout 3
            nb_get_retry 3
            delay_before_retry 3
        }
    }
}

```
**将MASTER上的配置同步到BACKUP服务器并相应修改**
```
# scp -P 16804 /etc/keepalived/keepalived.conf root@kp-bt-04:/etc/keepalived/

```
**配置iptables规则**
```
# iptables -I INPUT -d 224.0.0.0/8 -j ACCEPT
# iptables -I INPUT -p vrrp -j ACCEPT
# iptables -I INPUT -p tcp --dport 80 -j ACCEPT
# service iptables save
```
**启动keepalived服务**
```
# service keepalived start
```
**2. Realserver配置**
**创建一个脚本配置arp抑制及绑定vip**
```
# vim /home/vip-add.sh

#!/bin/bash  
#   
# Script to start LVS DR real server.   
# description: LVS DR real server   
#   
.  /etc/rc.d/init.d/functions
VIP=x.x.x.x   #这里根据需要改成自己的VIP地址
host=`/bin/hostname`
case "$1" in  
start)   
       # Start LVS-DR real server on this machine.   
        /sbin/ifconfig lo down   
        /sbin/ifconfig lo up   
        echo 1 > /proc/sys/net/ipv4/conf/lo/arp_ignore   
        echo 2 > /proc/sys/net/ipv4/conf/lo/arp_announce   
        echo 1 > /proc/sys/net/ipv4/conf/all/arp_ignore   
        echo 2 > /proc/sys/net/ipv4/conf/all/arp_announce
        /sbin/ifconfig lo:0 $VIP broadcast $VIP netmask 255.255.255.255 up  
        /sbin/route add -host $VIP dev lo:0
;;  
stop)
        # Stop LVS-DR real server loopback device(s).  
        /sbin/ifconfig lo:0 down   
        echo 0 > /proc/sys/net/ipv4/conf/lo/arp_ignore   
        echo 0 > /proc/sys/net/ipv4/conf/lo/arp_announce   
        echo 0 > /proc/sys/net/ipv4/conf/all/arp_ignore   
        echo 0 > /proc/sys/net/ipv4/conf/all/arp_announce
;;  
status)
        # Status of LVS-DR real server.  
        islothere=`/sbin/ifconfig lo:0 | grep $VIP`   
        isrothere=`netstat -rn | grep "lo:0" | grep $VIP`   
        if [ ! "$islothere" -o ! "isrothere" ];then   
            # Either the route or the lo:0 device   
            # not found.   
            echo "LVS-DR real server Stopped."   
        else   
            echo "LVS-DR real server Running."   
        fi   
;;   
*)   
            # Invalid entry.   
            echo "$0: Usage: $0 {start|status|stop}"   
            exit 1   
;;   
esac

该脚本来源：http://lovelace.blog.51cto.com/1028430/1550188
```
启动该脚本
```
# chmod +x vip-add.sh
# ./vip-add.sh start
```
测试访问正常。