---
title: 一个关于屏蔽恶意IP的shell脚本
date: 2015-12-21
categories: Linux
tags: block_ip

---

最近，因为工作上的需求，需要写一个脚本来实现用户输入一个IP，然后自动添加到iptables拒绝列表以及hosts.deny文件中，以实现拦截恶意IP访问的目的。因为之前写过一个功能简单的脚本，为了省事就直接拿过来改了改，主要想实现以下几点需求：
**1.拒绝IP访问：**
提示用户输入一个IP，然后将此IP添加到iptables拒绝列表，同时将此IP添加到hosts.deny文件中，实现拒绝IP访问。
**2.查找IP是否被拒绝并提示用户是否删除：**
提示用户输入一个IP，然后查询此IP是否存在于iptables拒绝列表、hosts.deny文件、route list，将查询结果输出到屏幕；同时输出一个选项菜单，让用户选择是否从拒绝列表中删除IP。

<!-- more -->


早前的脚本只有添加拒绝IP和查询IP是否被拒绝这两个功能，并无查询后删除的功能，代码如下：
```
#!/bin/bash
#
#version: 1.0.1
#by: lucissfer
#date: 2015-02-26 05:00

echo "The defined Options are:"
echo "	1: Drop IP to blocklist"
echo "	2: Find ip from the blocklist"
echo "	Any other character (except 1,2) exits"
read -p "Select Options (1-2): " option
if [ "$option" == "1" ]
then
	read -p "Please Input IP address: " ip
	iptables -I INPUT -s $ip -j DROP
	echo -e "\033[31m$ip\033[0m already be dropped !!!!"
	exit
elif [ "$option" == "2" ]
then
	read -p "Please Input IP address: " IP
	iptables -nvL --line | grep $IP &> /dev/null
	if [ $(echo $?) -lt 1 ]
	then
		echo -e "\n"
		echo -e "\033[32miptables: \033[0m"
		iptables -nvL --line | grep $IP
	else
		echo -e "\n"
		echo -e "\033[32miptables:\033[0m \n\033[31mDoes not exist!!!\033[0m"
	fi
	cat /etc/hosts.deny | grep $IP &> /dev/null
	if [ $(echo $?) -lt 1 ]
	then
		echo -e "\n"
		echo -e "\033[32mhosts.deny: \033[0m"
		cat /etc/hosts.deny | grep $IP
	else
		echo -e "\n"
		echo -e "\033[32mhosts.deny:\033[0m \n\033[31mDoes not exist!!!\033[0m"
	fi
	route -n | grep $IP &> /dev/null
	if [ $(echo $?) -lt 1 ]
	then
		echo -e "\n"
		echo -e "\033[32mroute blocklist: \033[0m"
		route -n | grep $IP
	else
		echo -e "\n"
		echo -e "\033[32mroute blocklist:\033[0m \n\033[31mDoes not exist!!!\033[0m"
	fi
else
	echo -e "\n"
	echo -e "\033[31mUnknown Options.\033[0m"
fi

```

***重新修改后的脚本代码如下：***
```
#!/bin/bash
#
#version: 1.0.2
#by: lucissfer
#date: 2015-12-15 17:00

add_ip() {
	iptables -I INPUT -s $ip -j DROP
	echo "ALL: $ip" >> /etc/hosts.deny
	echo -e "\033[31m$ip\033[0m has been added to the blocklist !!!!"
}

find_ip() {
	iptables -nvL --line | grep $ip &> /dev/null
	if [ $(echo $?) -lt 1 ]
	then
		echo -e "\n"
		echo -e "\033[32miptables: \033[0m"
		iptables -nvL --line | grep $ip
	else
		echo -e "\n"
		echo -e "\033[32miptables:\033[0m \n\033[31mDoes not exist!!!\033[0m"
	fi
	cat /etc/hosts.deny | grep $ip &> /dev/null
	if [ $(echo $?) -lt 1 ]
	then
		echo -e "\n"
		echo -e "\033[32mhosts.deny: \033[0m"
		cat /etc/hosts.deny | grep $ip
	else
		echo -e "\n"
		echo -e "\033[32mhosts.deny:\033[0m \n\033[31mDoes not exist!!!\033[0m"
	fi
	route -n | grep $ip &> /dev/null
	if [ $(echo $?) -lt 1 ]
	then
		echo -e "\n"
		echo -e "\033[32mroute blocklist: \033[0m"
		route -n | grep $ip
	else
		echo -e "\n"
		echo -e "\033[32mroute blocklist:\033[0m \n\033[31mDoes not exist!!!\033[0m"
	fi
}

remove_ip() {
	iptables -nvL --line | grep $ip &> /dev/null
	if [ $(echo $?) -lt 1 ]
	then
		iptables -D INPUT -s $ip -j DROP
		iptables -nvL --line | grep $ip &> /dev/null
		while [ $(echo $?) -lt 1 ] 
		do
			iptables -D INPUT -s $ip -j DROP
			iptables -nvL --line | grep $ip &> /dev/null
		done
		echo -e "\033[31m$ip\033[0m has been removed from iptables."
	else
		echo -e "\033[32miptables: \033[0m\033[31m$ip\033[0m does not exist."
	fi
	echo -e "\n"
	sed -i "/$ip/d" /etc/hosts.deny &> /dev/null
	echo -e "\033[31m$ip\033[0m has been removed from hosts.deny."
	echo -e "\n"
	ip route del $ip &> /dev/null
	if [ $(echo $?) -lt 1 ]
	then
		echo -e "\033[31m$ip\033[0m has been removed from routing list."
	else
		echo -e "\033[31m$ip\033[0m does not exist."
	fi
}


echo "The defined Options are:"
echo "	1: Add ip to blocklist"
echo "	2: Find ip from the blocklist"
echo "	Any other character (except 1,2) exits"

read -p "Select Options (1-2): " option
if [ "$option" == "1" ]
then
	read -p "Please Input ip address('q' to quit): " ip
	until [[ "$ip" == "q" ]]; do
		add_ip
		read -p "Please Input ip address('q' to quit): " ip
	done
elif [ "$option" == "2" ]
then
	read -p "Please Input ip address('q' to quit): " ip
	until [[ "$ip" == "q" ]]; do
		find_ip
		read -p "Whether to remove $ip('y' or 'n'): " option
		if [ "$option" == "y" ]
		then
			remove_ip	
		fi
		read -p "Please Input ip address('q' to quit): " ip
	done
else
	echo -e "\n"
	echo -e "\033[31mUnknown Options.\033[0m"
fi	
```

此文仅作记录，待我日后水平更高了，再回来重新改写，目前凑合着用吧。
