---
title: MySQL 5.7源码编译安装几处变化
date: 2016-09-27
categories: 
 - Linux
 - MySQL

tags: 
 - MySQL5.7
 - 源码编译变化

---

> **前言**：因为之前blog一直放在朋友的vps上，一来管理不便，二来也麻烦人。于是，花了点小钱在XX主机买了一个香港VPS，然后就准备开始部署blog环境。部署MySQL的时候，想尝尝鲜，就下载了最新的MySQL5.7.15源码编译安装，在编译安装的过程中踩了不少坑。究其主要原因，还是因为MySQL5.7相对于前面的版本做了一些小改动，在编译安装的过程中有一些变化，在此就将我遇到的坑整理出来与大家分享分享。

**CMAKE版本**
在MySQL的源码编译安装过程中需要使用cmake来安装，而在MySQL5.7的编译安装过程中要求cmake版本最低为2.8，如果版本低于2.8则需要升级cmake版本。

查询版本命令：
```shell
# cmake --version
cmake version 3.6.2
CMake suite maintained and supported by Kitware (kitware.com/cmake)
```
升级cmake有两种方法，可以直接使用yum工具来升级，也可以直接去cmake官网下载源码包然后编译安装。目前常见yum源中的cmake版本都在2.8.X，这里就不细说了，简单说下如何编译安装cmake。
```shell
# wget https://cmake.org/files/v3.6/cmake-3.6.2.tar.gz
# tar zxvf cmake-3.6.2.tar.gz
# cd cmake-3.6.2
# ./bootstrap
# make && make install
# cmake --version
cmake version 3.6.2
```
如果上述编译安装过程中报错，先检查是否安装gcc库。

**Boost库支持**
MySQL5.7的编译安装过程需要boost类库支持，可以直接在CMAKE编译参数中指定下载，也可以下载到指定目录，然后在CMAKE编译参数中指定boost位置。

CMAKE编译参数中指定下载
```shell
# cmake ............
    -DDOWNLOAD_BOOST=1\    #指定是否下载boost
    -DWITH_BOOST=/usr/local/boost  #指定boost位置
```
不过依据我多次编译MySQL5.7的经验，在CMAKE编译参数中指定下载boost会因为网络原因出现错误，最好还是直接下载到服务器，然后编译安装时指定目录。

直接下载boost到服务器并在编译安装时指定目录
```shell
# wget -o /usr/local/boost/boost_1_59_0.tar.gz http://ncu.dl.sourceforge.net/project/boost/boost/1.59.0/boost_1_59_0.tar.gz
# cmake ............
    -DWITH_BOOST=/usr/local/boost  #指定boost位置
```
此处下载完成后无需解压，MySQL在CMAKE编译配置时会自动解压。

**MySQL初始化数据库**
MySQL5.7跟以前版本的MySQL在编译安装过程中最大的变化还是初始化数据库不再使用scripts/mysql_install_db脚本来实现，而是直接使用bin/mysqld指定--initialize参数来实现。
```shell
# bin/mysqld --initialize --user=mysql --basedir=/usr/local/mysql/ --datadir=/usr/local/mysql/data/
```
**MySQL5.7数据库初始密码**
在MySQL5.7版本以前，编译安装完成MySQL后，首次登录无需密码，而在MySQL5.7中，在编译安装完成，初始化MySQL数据库时会生成一个随机密码，首次登录需使用随机密码。
```shell
# bin/mysqld --initialize --user=mysql --basedir=/usr/local/mysql/ --datadir=/usr/local/mysql/data/
2016-09-27T08:45:57.023651Z 1 [Note] A temporary password is generated for root@localhost: dh9>qmyaBIZe

修改root密码
# mysqladmin -uroot password 'password' -p'dh9>qmyaBIZe'
```

大体上，MySQL5.7与以前版本的在编译安装过程中就这几处变化，其他的与之前版本的编译安装过程无异，仅供参考，如有不同意见，欢迎补充。