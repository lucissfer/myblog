---
title: pyenv安装配置
date: 2018-05-29
categories: 
 - Linux
 - Python

tags: 
 - Python
 - pyenv
 
---

> pyenv是一个Python多版本管理工具，它可以改变全局的Python版本，安装多个版本的Python，设置目录级别的Python版本，还能创建和管理virtual python environments 。所有的设置都是用户级别的操作，不需要sudo 命令。
pyenv通过系统修改环境变量来实现Python不同版本的切换，它在PATH的最前面插入了一个垫片路径（shims）：~/.pyenv/shims:/usr/local/bin:/usr/bin:/bin。所有对 Python 可执行文件的查找都会首先被这个 shims 路径截获，从而使后方的系统路径失效。

**1. 安装pyenv**
======
**1.1 git拉取pyenv代码**
------
```shell
# git clone https://github.com/pyenv/pyenv.git ~/.pyenv
```

<!-- more -->

**1.2 修改配置文件**
------
```shell
# echo 'export PYENV_ROOT="$HOME/.pyenv"' >> ~/.bash_profile
# echo 'export PATH="$PYENV_ROOT/bin:$PATH"' >> ~/.bash_profile
# echo -e 'if command -v pyenv 1>/dev/null 2>&1; then\n  eval "$(pyenv init -)"\nfi' >> ~/.bash_profile
```
**1.3 重新载入变量配置**
------
```shell
# source ~/.bashrc
```
**1.4 验证安装**
------
```shell
# pyenv versions
```

**2. 使用pyenv安装多版本Python**
======
**2.1 安装依赖包**
------
在使用pyenv安装Python之前，需要安装相应的依赖包，否则在安装过程中会报错。
```shell
# yum install -y gcc*
# yum install -y readline readline-devel readline-static
# yum install -y zlib-devel
# yum install -y bzip2-devel bzip2-libs
# yum install -y openssl openssl-devel openssl-static
# yum install -y sqlite-devel
```
**2.2 pyenv常用命令**
------
查看本机安装 Python 版本
```shell
# pyenv versions
* 表示当前正在使用的 Python 版本
```
查看可安装Python版本
```shell
# pyenv install -l
```
python安装与卸载
```shell
# pyenv install 2.7.15   
# 安装python
# pyenv uninstall 2.7.15 
# 卸载python
```
python切换
```shell
# pyenv global 2.7.15  
# 设置全局的 Python 版本，通过将版本号写入 ~/.pyenv/version 文件的方式。
# pyenv local 2.7.15 
# 设置 Python 本地版本，通过将版本号写入当前目录下的 .python-version 文件的方式。通过这种方式设置的 Python 版本优先级较 global 高。

python优先级
shell > local > global
pyenv 会从当前目录开始向上逐级查找 .python-version 文件，直到根目录为止。若找不到，就用 global 版本。

# pyenv shell 2.7.15 # 设置面向 shell 的 Python 版本，通过设置当前 shell 的 PYENV_VERSION 环境变量的方式。这个版本的优先级比 local 和 global 都要高。–unset 参数可以用于取消当前 shell 设定的版本。
# pyenv shell --unset
# pyenv rehash  # 创建垫片路径（为所有已安装的可执行文件创建 shims，如：~/.pyenv/versions/*/bin/*，因此，每当你增删了 Python 版本或带有可执行文件的包（如 pip）以后，都应该执行一次本命令）
```
查看所有pyenv支持命令
```shell
# pyenv commands
```
**2.3 安装过程中遇到的相关问题解决**
------
### **2.3.1 安装Python过程慢**
pyenv安装Python过程
```shell
pyenv默认会从官网下载相应Python压缩包，放到/tmp目录下，然后在/tmp目录编译安装，安装在~/.pyenv/versions/下面。
```
解决下载安装慢的问题
```shell
因为pyenv默认会从Python官网下载压缩包，因为众所周知的原因，国内访问Python官网不稳定，因此在下载过程中会非常慢，解决该问题有两个办法：
1. 手动将Python压缩包下载到~/.pyenv/cache/目录下，pyenv会校验md5值和完整性，确认无误的话就不会重新下载直接从这里安装；这里有个需要注意的地方，需要把下载的Python压缩包后缀名由.tgz修改为.tar.gz（切记不能采用把.tgz解压之后再压缩成.tar.gz 的方式，因为这样的话会导致源文件的md5值发生变化而校验失败重新下载。）
2. 直接修改pyenv配置文件，将Python下载地址修改为国内Python镜像源地址，在此，推荐第二种方法，我这里使用的是sohu的镜像源；修改~/.pyenv/plugins/python-build/share/python-build/目录下对应版本号文件，你需要安装哪个版本就修改哪个版本号，替换下载地址为sohu镜像源地址：
# cd ~/.pyenv/plugins/python-build/share/python-build/
# vim 3.6.5
  #install_package "Python-3.6.5" "https://www.python.org/ftp/python/3.6.5/Python-3.6.5.tar.xz#f434053ba1b5c8a5cc597e966ead3c5143012af827fd3f0697d21450bb8d87a6
  install_package "Python-3.6.5" "http://mirrors.sohu.com/python/3.6.5/Python-3.6.5.tar.xz#f434053ba1b5c8a5cc597e966ead3c5143012af827fd3f0697d21450bb8d87a6
```
### **2.3.2 pip安装库timeout**
pip安装库的时候，也会经常出现现在速度很慢或者timeout的状况，更换成国内镜像源即可解决问题
```shell
创建一个pip.conf文件
# mkdir ~/.pip
# vim ~/.pip/pip.conf
[global]
index-url = http://mirrors.aliyun.com/pypi/simple/

[install]
trusted-host=mirrors.aliyun.com
```

