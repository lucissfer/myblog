---
title: 使用Nginx来配置服务端兼容APP接口多版本
date: 2018-03-20
categories: 
 - Linux
 - Nginx/OpenResty

tags: 
 - openResty
 - app
 - 多版本

---

> 移动互联网时代，讲究的是快速迭代，为了完善产品功能，一款APP需要不断的更新版本发布功能；而为了不影响用户体验，很多时候我们无法做到每个版本都强制用户更新；这样一来势必要保证APP多版本共存，作为APP与服务端交互的交互的api接口也将存在多个接口共存的情况，所以，我们必须考虑到如何实现APP接口多版本共存。

**1. APP接口多版本共存的几种实现方式**
========
**1.1 URL请求中加入版本信息**
--------
> 例如：
www.xxx.com/api.xxx?version=v1
www.xxx.com/api.xxx?version=v2
**1.2 使用不同子域名来区分不同版本的api接口**
--------
> 例如：
api1.xxx.com
api2.xxx.com
**1.3 URL中加入不同版本路径来区分不同版本的api接口**
--------
> 例如：
www.xxx.com/v1/api
www.xxx.com/v2/api
**1.4 在URL提交header中加入版本信息**
--------
> 例如：
header信息中直接添加一个字段：http_AppVersion = 1

<!-- more -->

**2. 我们选择的方案**
========
在我们的技术选型过程中，不远将版本信息暴露在URL中，因此我们选择将版本信息放在header中，通过服务端来判断app版本信息并将请求分发到不同的接口服务上。
因此，我们选择在接口服务前面加一个Nginx来反代请求并分发，而Nginx原生支持用户自定义header，所以我们只需要在提交的header信息中定义一个http_AppVersion字段，APP端请求到Nginx服务器，Nginx服务器根据请求过来的header信息中的http_AppVersion字段值将不同版本的APP请求转发的不同的api接口服务上。

**3. Nginx的具体配置**
========
```shell
        location / {
        if ($http_AppVersion = "1_0_1") {
        proxy_pass https://api1.xxx.com/1_0_1$request_uri;
        break;
        }
        if ($http_AppVersion = "1.0.2") {
        proxy_pass https://api1.xxx.com/1_0_2$request_uri;
        break;
        }
        if ($http_AppVersion = "1.0.3") {
        proxy_pass https://api1.xxx.com/1_0_3$request_uri;
        break;
        }
        if ($http_AppVersion = "1.0.4") {
        proxy_pass https://api1.xxx.com/1_0_4$request_uri;
        break;
        }
        if ($http_AppVersion = "") {
        proxy_pass https://api1.xxx.com/1_0_1$request_uri;
        break;
        }
        }

```





