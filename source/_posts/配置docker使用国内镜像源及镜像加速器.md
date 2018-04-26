---
title: 配置docker使用国内镜像源及镜像加速器
date: 2018-04-26
categories: 
 - Linux
 - Docker

tags: 
 - docker
 - 镜像源

---

因为众所周知的原因，在国内访问docker官方yum源经常会出现不可知状态，为了正常使用docker，我们需要将docker yum源修改为国内yum源来解决访问慢或者无法访问的问题。
目前国内大多数开放镜像站都提供了docker yum源，如：阿里云、USTC等，此处以阿里云为例。


**1. 修改docker-ce.repo文件，配置国内镜像站地址**
------
docker-ce.repo文件可从阿里云或USTC镜像站下载，阿里云下载地址：https://mirrors.aliyun.com/docker-ce/linux/centos/docker-ce.repo
>不知为何，阿里云与USTC镜像站上默认的docker-ce.repo文件内部地址均是指向docker官方站https://download-stage.docker.com 这样导致直接下载下来的repo文件无法正常使用，需要将baseurl修改为国内镜像站的地址。
```shell
# vim /etc/yum.repos.d/docker-ce.repo
# sed -i 's@https://download-stage.docker.com/linux/centos/7/@https://mirrors.aliyun.com/docker-ce/linux/centos/7/@g' /etc/yum.repos.d/docker-ce.repo
# sed -i 's@https://download-stage.docker.com/linux/centos/gpg@https://mirrors.aliyun.com/docker-ce/linux/centos/gpg@g' /etc/yum.repos.d/docker-ce.repo
```
修改完成后，yum安装docker就可以直接使用国内yum源了。

<!-- more -->

**2. 修改/etc/docker/daemon.json文件，配置docker镜像加速器**
------
配置完docker的国内yum源仅仅解决了yum安装docker时的访问问题，但在docker实际使用中还面临另外一个问题；
docker默认镜像仓库Docker Hub服务器位于国外，因此在国内访问的时候依然会出现各种故障，为此docker提供了一个镜像加速器的设置，
可以通过配置位于国内的**镜像加速器**来加速docker镜像的拉取。
Docker 官方和国内很多云服务商都提供了国内加速器服务，例如：
> [Docker 官方提供的中国 registry mirror][1]
[阿里云加速器][2]
[DaoCloud 加速器][3]
后两者需要注册相关账号才可以使用。

修改/etc/docker/daemon.json文件，添加以下内容，如此文件不存在则创建之；
```shell
# vim /etc/docker/daemon.json
{
"registry-mirrors": [
"https://registry.docker-cn.com"
]
}
```
修改完成后，需重启服务生效；
```shell
# systemctl daemon-reload
# systemctl restart docker
```
到此为止，可以愉快的使用docker了。

  [1]: https://docs.docker.com/registry/recipes/mirror/#use-case-the-china-registry-mirror
  [2]: https://cr.console.aliyun.com/#/accelerator
  [3]: https://www.daocloud.io/mirror#accelerator-doc