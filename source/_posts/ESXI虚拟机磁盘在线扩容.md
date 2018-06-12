---
title: ESXI虚拟机磁盘在线扩容
date: 2018-06-12
categories: 
 - Linux
 - ESXI

tags: 
 - esxi
 - 磁盘在线扩容

---

内网有一台ESXI上的虚拟机，用来做构建服务的，因为构建项目逐渐增加，磁盘空间渐渐不足，严重影响使用。
为解决问题，当务之急是将磁盘分区进行扩容，因为磁盘分区做的LVM，可以很方便的动态扩容，在物理机上可以通过加硬盘的方式来解决问题，而ESXI的虚拟机就更方便了，直接将虚拟机关机修改磁盘大小即可，但是修改完的硬盘空间并不会自动扩展到磁盘分区中，还需要我们做一些操作才可以使用，具体操作如下：

**1. 创建新分区**
======
ESXI修改完磁盘大小后，增加的磁盘空间表现为当前磁盘剩余未分配空间，需要使用剩余未分配空间新建分区
```shell
# fdisk /dev/sda
n       （新建分区）
p       （选择分区类型主分区或扩展分区）
3       （选择分区编号）
回车
回车
t	（修改分区类型）
3	（选择分区）
8e	（Changed type of partition 'Linux' to 'Linux LVM'，修改成LVM类型）
w	（写分区表退出）
```
<!-- more -->

```shell
使用命令重新读取分区表，或者重启机器
# partprobe
Warning: Unable to open /dev/sr0 read-write (Read-only file system).  /dev/sr0 has been opened read-only.

Centos6系统上使用
# partx
```
```shell
格式化新磁盘分区
xfs文件系统
# mkfs.xfs /dev/sda3       （此处分区格式要与已有的LVM卷中分区格式一致）
EXT4文件系统
# mkfs.ext4 /dev/sda3
```
**2. 添加新LVM分区到已有的LVM组，实现扩容**
======
进入LVM管理
```shell
# lvm
lvm>
```
```shell
初始化新分区
lvm> pvcreate /dev/sda3
```
```shell
查看卷组名
lvm> vgdisplay 
  --- Volume group ---
  VG Name               test_build
```
```shell
将初始化过的分区加入到虚拟卷组
lvm> vgextend test_build /dev/sda3
  Volume group "test_build" successfully extended
```
```shell
扩展已有卷的容量
lvm> vgdisplay 
  --- Volume group ---
  VG Name               test_build
  System ID             
  Format                lvm2
  Metadata Areas        2
  Metadata Sequence No  4
  VG Access             read/write
  VG Status             resizable
  MAX LV                0
  Cur LV                2
  Open LV               2
  Max PV                0
  Cur PV                2
  Act PV                2
  VG Size               <399.53 GiB
  PE Size               4.00 MiB
  Total PE              102279
  Alloc PE / Size       51080 / 199.53 GiB
  Free  PE / Size       51199 / <200.00 GiB
  VG UUID               wVZavM-oLX7-iWf1-fKiO-TGVM-Oa0r-2mcTsD

lvm> lvextend -l +51199 /dev/mapper/test_build-data
  Size of logical volume test_build/data changed from 152.96 GiB (39159 extents) to 352.96 GiB (90358 extents).
  Logical volume test_build/data successfully resized.
上述参数中，
-l,指定逻辑卷的大小，单位为PE数;
51199为通过vgdisplay命令查询到的卷中空闲空间，目录参数为df命令查询到的需要扩展的挂载点位置。
```
```shell
查看卷容量
lvm> pvdisplay
  --- Physical volume ---
  PV Name               /dev/sda2
  VG Name               test_build
  PV Size               199.53 GiB / not usable 3.00 MiB
  Allocatable           yes (but full)
  PE Size               4.00 MiB
  Total PE              51080
  Free PE               0
  Allocated PE          51080
  PV UUID               2gmX3A-Bpz4-hCQ0-5fjr-CiCM-peYZ-BMDi9W
   
  --- Physical volume ---
  PV Name               /dev/sda3
  VG Name               test_build
  PV Size               200.00 GiB / not usable 4.00 MiB
  Allocatable           yes (but full)
  PE Size               4.00 MiB
  Total PE              51199
  Free PE               0
  Allocated PE          51199
  PV UUID               wJe39M-0326-n2Ge-6m2d-IlTR-Gubg-UXRhie

lvm> quit
```
**3. 文件系统扩容**
======
卷扩容完成后，系统并不能直接使用扩容空间，还需要将文件系统扩容
```shell
xfs文件系统
# xfs_growfs /dev/mapper/test_build-data
meta-data=/dev/mapper/test_build-data isize=512    agcount=4, agsize=10024704 blks
         =                       sectsz=512   attr=2, projid32bit=1
         =                       crc=1        finobt=0 spinodes=0
data     =                       bsize=4096   blocks=40098816, imaxpct=25
         =                       sunit=0      swidth=0 blks
naming   =version 2              bsize=4096   ascii-ci=0 ftype=1
log      =internal               bsize=4096   blocks=19579, version=2
         =                       sectsz=512   sunit=0 blks, lazy-count=1
realtime =none                   extsz=4096   blocks=0, rtextents=0
data blocks changed from 40098816 to 92526592

EXT4文件系统
# resize2fs /dev/mapper/test_build-data
```
```shell
查看分区大小
# df -hl
Filesystem                   Size  Used Avail Use% Mounted on
/dev/mapper/test_build-root   47G  2.3G   45G   5% /
devtmpfs                     908M     0  908M   0% /dev
tmpfs                        920M     0  920M   0% /dev/shm
tmpfs                        920M  8.8M  911M   1% /run
tmpfs                        920M     0  920M   0% /sys/fs/cgroup
/dev/mapper/test_build-data  353G  456M  353G   1% /data
/dev/sda1                    473M  169M  305M  36% /boot
tmpfs                        184M     0  184M   0% /run/user/0
```
扩容成功




