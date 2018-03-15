---
title: openresty编译参数详解
date: 2016-12-01
categories: 
 - Linux
 - Nginx/OpenResty

tags: 
 - openresty
 - 编译参数


---

|参数选项                                              |  说明|
|-------------------------------------------------|--------------|
|  --help                             |		this message **帮助选项**|
||
|  --prefix=PATH                      |		set the installation prefix (default to /usr/local/openresty)   **设置安装路径**|
||
|  --with-debug                       |		enable debug logging    **启用调试日志**|
|  --with-dtrace-probes               |		enable dtrace USDT probes   **启用DTrace USDT探针**    （DTrace 提供丰富的用于监视系统各方面（从内核直到应用程序）运行情况的探测。我们可以在不修改应用程序的情况下执行很多检查，但是要想获得详细的统计数据，就需要在应用程序中添加探测。USDT 让开发人员可以在代码中重要的位置添加特定的探测。还可以使用 USDT 从正在运行的应用程序获取数据，这些数据可作为跟踪应用程序的探测的参数而被访问。）|
|  --with-dtrace=PATH                 |		set dtrace utility pathname **设置DTrace路径**|
||
|  --with-no-pool-patch               |		enable the no-pool patch for debugging memory issues    **启用无池补丁调试内存问题**    （nginx的内存池可能会干扰nginx发现内存问题的第一现场，所以可以考虑在构造openresty时禁用nginx 的内存池，即使用 --with-no-pool-patch 选项）|
||
|  -jN                                |		pass -jN option to make while building the bundled Lua 5.1 interpreter or LuaJIT 2.1|
||**pass -jN选项，在构建捆绑的Lua 5.1解释器或LuaJIT 2.1时**|
|  --without-http_echo_module         |		disable ngx_http_echo_module    **禁用ngx_http_echo_module**    （nginx的echo模块可以在nginx的url访问中通过echo命令输出字符到用户的浏览器，一般用来调试输出信息，检测nginx的可访问性、配置正确性。）|
|  --without-http_xss_module          |		disable ngx_http_xss_module     **禁用ngx_http_xss_module** 跨站点脚本支持|
|  --without-http_coolkit_module      |		disable ngx_http_coolkit_module **禁用ngx_http_coolkit_module** （ngx_http_coolkit_module是一个小而有用的nginx插件模块集合）|
|  --without-http_set_misc_module     |		disable ngx_http_set_misc_module    **禁用ngx_http_set_misc_module**    （ngx_http_set_misc_module模块是标准的HttpRewriteModule指令的扩展，提供更多的功能，如URI转义与非转义、JSON引述、Hexadecimal/MD5/SHA1/Base32/Base64编码与解码、随机数等等。）|
|  --without-http_form_input_module   |		disable ngx_http_form_input_module  **禁用ngx_http_form_input_module**  （ngx_http_form_input_module是 Openresty 中一个用于处理 HTTP 请求的 POST 以及 PUT 方法，在协议头 Content-Type 是 application/x-www-form-urlencoded 的情况下，解析请求实体内容并按 nginx 变量存储的模块。）|
|  --without-http_encrypted_session_module  |	disable ngx_http_encrypted_session_module   **禁用ngx_http_encrypted_session_module**   （ngx_http_encrypted_session_module是一个加密解密nginx变量值的模块，此模块提供了基于AES-256与Mac的变量加密和解密支持，此模块通常与ngx_set_misc模块和标准rewrite模块的指令一起使用，此模块可用于实现简单的用户登录和ACL。）|
|  --without-http_srcache_module      |		disable ngx_http_srcache_module **禁用ngx_http_srcache_module**    （此模块为任意nginx位置提供了一个透明缓存层，为location增加了透明的基于subrequest的缓存层（类似于使用upstream或者甚至提供静态磁盘文件的缓存层）。）|
|  --without-http_lua_module          |		disable ngx_http_lua_module **禁用ngx_http_lua_module**|
|  --without-http_lua_upstream_module |		disable ngx_http_lua_upstream_module    **禁用ngx_http_lua_upstream_module**    （ngx_http_lua_upstream_module是openresty的负载均衡模块）|
|  --without-http_headers_more_module |		disable ngx_http_headers_more_module    **禁用ngx_http_headers_more_module**    （ngx_http_headers_more_module是nginx定制header返回信息模块，用于添加、设置和清除输入和输出的头信息。nginx源码没有包含该模块，需要另行添加。该模块是ngx_http_headers_module模块的增强版，提供了更多的实用工具，比如复位或清除内置头信息，如Content-Type, Content-Length, 和Server。可以允许你使用-s选项指定HTTP状态码，使用-t选项指定内容类型，通过more_set_headers 和 more_clear_headers 指令来修改输出头信息。）|
|  --without-http_array_var_module    |		disable ngx_http_array_var_module   **禁用ngx_http_array_var_module**   （此模块为nginx.conf提供了数组类型的nginx变量。）|
|  --without-http_memc_module         |		disable ngx_http_memc_module    **禁用ngx_http_memc_module**    （memc模块扩展了Nginx标准的memcache模块，增加了set、add、delete等memcache命令）|
|  --without-http_redis2_module       |		disable ngx_http_redis2_module  **禁用ngx_http_redis2_module**  （redis2-nginx-module 是一个支持 Redis 2.0 协议的 Nginx upstream 模块，它可以让 Nginx 以非阻塞方式直接防问远方的 Redis 服务，同时支持 TCP 协议和 Unix Domain Socket 模式，并且可以启用强大的 Redis 连接池功能。）|
|  --without-http_redis_module        |		disable ngx_http_redis_module   **禁用ngx_http_redis_module**   （此模块是一个简单的提供redis缓存的模块，目前仅提供select和get方法。）|
|  --without-http_rds_json_module     |		disable ngx_http_rds_json_module    **禁用ngx_http_rds_json_module**    （此模块用来做数据格式转换）|
|  --without-http_rds_csv_module      |		disable ngx_http_rds_csv_module **禁用ngx_http_rds_csv_module** （此模块用来做数据格式转换）|
|  --without-ngx_devel_kit_module     |		disable ngx_devel_kit_module    **禁用ngx_devel_kit_module**    （Nginx的开发套件）|
|  --without-http_ssl_module          |		disable ngx_http_ssl_module **禁用ngx_http_ssl_module** （该模块使Nginx支持SSL协议，提供HTTPS服务。**该模块的安装依赖于OpenSSL。**）|
||
|  --with-http_iconv_module           |		enable ngx_http_iconv_module    **启用ngx_http_iconv_module**   （此模块使用libiconv来转换不同编码字符，依赖于libiconv。）|
|  --with-http_drizzle_module         |		enable ngx_http_drizzle_module  **启用ngx_http_drizzle_module**  （此模块使NGINX直接与MySQL或Drizzle（一个精简版的MySQL分支）数据库服务器通信）|
|  --with-http_postgres_module        |		enable ngx_http_postgres_module **启用ngx_http_postgres_module** （此模块允许NGINX直接与PostgreSQL数据库通信）|
||
|  --without-lua_cjson                |		disable the lua-cjson library   **禁用lua-cjson library**   （Lua CJSON是一个Lua c模块，提供快速的JSON解析和Lua的编码支持）|
|  --without-lua_redis_parser         |		disable the lua-redis-parser library    **禁用lua-redis-parser library**    （lua-redis解析器库实现了一个简单且快速的redis原始响应解析器，它构造相应的lua数据结构，以及一个构造redis raw请求的函数。）|
|  --without-lua_rds_parser           |		disable the lua-rds-parser library  **禁用lua-rds-parser library**  （这个Lua库可以用于将Drizzle Nginx模块和Postgres Nginx模块生成的Resty-DBD-Stream格式的数据解析为Lua数据结构。在过去，我们必须使用JSON作为中间数据格式，这在内存和CPU时间方面是相当低效的。为了最大化速度和最小化内存占用，这个库以纯C语言实现。默认情况下启用此库。）|
|  --without-lua_resty_dns            |		disable the lua-resty-dns library   **禁用lua-resty-dns library**   （非阻塞DNS（域名系统）解析器的Lua Nginx模块，基于cosocket API。）|
|  --without-lua_resty_memcached      |		disable the lua-resty-memcached library **禁用lua-resty-memcached library**    （Memcached客户端驱动程序模块，基于cosocket API的Lua Nginx模块。）|
|  --without-lua_resty_redis          |		disable the lua-resty-redis library **禁用lua-resty-redis library** （Lua Redis客户端驱动程序，基于cosocket API的Lua Nginx模块。）|
|  --without-lua_resty_mysql          |		disable the lua-resty-mysql library **禁用lua-resty-mysql library** （Lua MySQL客户端驱动程序，基于cosocket API的Lua Nginx模块。）|
|  --without-lua_resty_upload         |		disable the lua-resty-upload library    **禁用lua-resty-upload library**    （基于Lua Nginx模块的cosocket API用于HTTP文件上传流阅读器和分析器。）|
|  --without-lua_resty_upstream_healthcheck|		disable the lua-resty-upstream-healthcheck library **禁用lua-resty-upstream-healthcheck library**  （此模块是纯Lua的Nginx上游服务器健康检查器。）|
|  --without-lua_resty_string         |		disable the lua-resty-string library    **禁用lua-resty-string library**    （一个Lua库，为Lua Nginx模块提供字符串实用程序和通用哈希函数。）|
|  --without-lua_resty_websocket      |		disable the lua-resty-websocket library    **禁用lua-resty-websocket library** （这个Lua库实现了一个非阻塞WebSocket服务器和基于Lua Nginx模块的cosocket API的非阻塞WebSocket客户端。）|
|  --without-lua_resty_lock           |		disable the lua-resty-lock library  **禁用lua-resty-lock library** （这个Lua库实现了一个基于Lua Nginx模块的共享内存字典的简单非阻塞互斥锁API。 主要用于消除“dog-pile effects”。dog-pile effect 指当网页缓存失效同时遇到大量请求，后端应用服务请求建立缓存，导致服务器卡顿甚至系统宕机的现象。）|
|  --without-lua_resty_lrucache       |		disable the lua-resty-lrucache library  **禁用lua-resty-lrucache library**  （实现OpenResty的Lua-land LRU缓存。）|
|  --without-lua_resty_core           |		disable the lua-resty-core library  **禁用lua-resty-core library**  （使用LuaJIT FFI实现Lua Nginx模块提供的Lua API。）|
||
|  --with-lua51                       |		enable and build the bundled standard Lua 5.1 interpreter **启用并构建捆绑的标准Lua 5.1解释器**|
|  --without-lua51                    |		disable the bundled standard Lua 5.1 interpreter    **禁用捆绑的标准Lua 5.1解释器**|
|  --with-lua51=DIR                   |		specify the external installation of Lua 5.1 by DIR **指定由外部DIR安装Lua 5.1**|
|  --with-luajit                      |		enable and build the bundled LuaJIT 2.1 (the default)   **启用并构建捆绑的LuaJIT 2.1（默认）**|
|  --with-luajit=DIR                  |		use the external LuaJIT 2.1 installation specified by DIR **使用指定的DIR安装LuaJIT 2.1**|
|  --with-luajit-xcflags=FLAGS        |		Specify extra C compiler flags for LuaJIT 2.1   **为LuaJIT 2.1指定额外的C编译器标志**|
|  --with-libdrizzle=DIR              |		specify the libdrizzle 1.0 (or drizzle) installation prefix  **指定libdrizzle 1.0（或drizzle）安装路径**|
|  --with-libpq=DIR                   |		specify the libpq (or postgresql) installation prefix   **指定libpq（或postgresql）安装路径**|
|  --with-pg_config=PATH              |		specify the path of the pg_config utility   **指定pg_config实用程序的路径**|
||
|**Options directly inherited from nginx**  **直接继承自nginx的选项**|     
||
|  --sbin-path=PATH                   |		set nginx binary pathname   **设置可执行文件放置路径**|
|  --conf-path=PATH                   |		set nginx.conf pathname **设置配置文件的放置路径**|
|  --error-log-path=PATH              |		set error log pathname  **设置error日志文件的放置路径**|
|  --pid-path=PATH                    |		set nginx.pid pathname  **设置pid文件的放置路径**|
|  --lock-path=PATH                   |		set nginx.lock pathname **设置lock文件的放置路径**|
|  --tapset-prefix=PATH               |		set systemtap tapset directory prefix **设置systemtap tapset目录路径**  |
|  --stap-nginx-path=PATH             |		set stap-nginx pathname **设置stap-nginx路径名**|
||
|  --user=USER                        |		set non-privileged user for worker processes    **为工作进程设置非特权用户**|
|  --group=GROUP                      |		set non-privileged group for worker processes   **为工作进程设置非特权组**|
||
|  --builddir=DIR                     |		set the build directory **设置构建目录**|
||
|  --with-select_module               |		enable select module    **使用select module处理事件驱动**|
|  --without-select_module            |		disable select module   **禁用select module**|
|  --with-poll_module                 |		enable poll module  **使用poll module处理事件驱动**|
|  --without-poll_module              |		disable poll module **禁用poll module**|
||
|  --with-threads                     |		enable thread pool support  **启用线程池支持**|
||
|  --with-file-aio                    |		enable file aio support **启用文件异步IO支持**|
|  --with-ipv6                        |		enable ipv6 support **启用ipv6支持**|
||
|  --with-http_realip_module          |		enable ngx_http_realip_module   **启用ngx_http_realip_module**  （该模块可以从客户端请求里的header信息（如X-Real-IP或者X-Forwared-For）中获取真正的客户端IP地址）|
|  --with-http_addition_module        |		enable ngx_http_addition_module **启用http addition module。该模块可以再返回客户端的HTTP包体头部或者尾部增加内容**|
|  --with-http_xslt_module            |		enable ngx_http_xslt_module **启用http xslt module。这个模块可以使XML格式的数据在发给客户端前加入XSL渲染，此模块依赖于libxml2和libxslt库。**|
|  --with-http_image_filter_module    |		enable ngx_http_image_filter_module **启用http image filter module。此模块将符合配置的图片实时压缩为指定大小（width*height）的缩略图再发送给用户，目前支持JPEG、PNG、GIF格式。此模块依赖于开源的libgd库。**|
|  --with-http_geoip_module           |		enable ngx_http_geoip_module    **启用http geoip module。该模块可以依据MaxMind GeoIP的IP地址数据库对客户端的IP地址得到实际的地理位置信息。**|
|  --with-http_sub_module             |		enable ngx_http_sub_module  **启用http sub module。该模块可以在Nginx返回客户端的HTTP响应包中将指定的字符串替换为自己需要的字符串。例如，在HTML的返回中，`将</head>替换为</head><script language="javascript" src="$script"></script>`**|
|  --with-http_dav_module             |		enable ngx_http_dav_module  **启用http dav module。这个模块可以让Nginx支持Webdav标准，如支持Webdav协议中的PUT、DELETE、COPY、MOVE、MKCOL等请求**|
|  --with-http_flv_module             |		enable ngx_http_flv_module  **启用http flv module。这个模块可以在向客户端返回响应时，对FLV格式的视频文件在header头做一些处理，使得客户端可以观看、拖动FLV视频**|
|  --with-http_gzip_static_module     |		enable ngx_http_gzip_static_module  **启用http gzip static module。如果采用gzip模块把一些文档进行gzip格式压缩后再返回给客户端，那么对同一个文件每次都会重新压缩，这是比较消耗服务器CPU资源的。gzip static模块可以在做gzip压缩前，先查看相同位置是否有已经做过gzip压缩的.gz文件，如果有就直接返回。这样就可以预先在服务器上做好文档的压缩，给CPU减负。**|
|  --with-http_auth_request_module    |		enable ngx_http_auth_request_module **启用http auth request module。这个是nginx的一个验证模块，这个模块允许您的nginx通过发送请求到后端服务器（一般是应用服务器，例如tomcat，或者php等）进行请求，并且根据请求决定是验证通过或者不通过。**|
|  --with-http_random_index_module    |		enable ngx_http_random_index_module **启用http random index module。该模块在客户端访问某个目录时，随机返回该目录下的任意文件。**|
|  --with-http_secure_link_module     |		enable ngx_http_secure_link_module  **启用http secure link module。该模块提供一种验证请求是否有效的机制。例如，它会验证URL中需要加入的token参数是否属于特定客户端发来的，以及检查时间戳是否过期。**|
|  --with-http_degradation_module     |		enable ngx_http_degradation_module  **启用http degradation module。该模块针对一些特殊的系统调用（如sbrk）做一些优化，如直接返回HTTP响应码为204或444，目前不支持Linux系统。**|
|  --with-http_stub_status_module     |		enable ngx_http_stub_status_module  **启用http stub status module。该模块可以让运行中的Nginx提供性能统计页面，获取相关的并发连接、请求的信息。**|
||
|  --without-http_charset_module      |		disable ngx_http_charset_module **禁用http charset module。这个模块可以将服务器发出的HTTP响应重编码。**|
|  --without-http_gzip_module         |		disable ngx_http_gzip_module    **禁用http gzip module。在服务器发出的HTTP响应包中，这个模块可以按照配置文件指定的content-type对特定大小的HTTP响应包体执行gzip压缩。**|
|  --without-http_ssi_module          |		disable ngx_http_ssi_module **禁用http ssi module。该模块可以在向用户返回的HTTP响应包体中加入特定的内容，如HTML文件中固定的页头和页尾。**|
|  --without-http_userid_module       |		disable ngx_http_userid_module  **禁用http userid module。该模块可以通过HTTP请求头部信息里的一些字段认证用户信息，以确定请求是否合法。**|
|  --without-http_access_module       |		disable ngx_http_access_module  **禁用http access module。该模块可以根据IP地址限制能够访问服务器的客户端。**|
|  --without-http_auth_basic_module   |		disable ngx_http_auth_basic_module  **禁用http auth basic module。该模块可以提供最简单的用户名/密码认证。**|
|  --without-http_autoindex_module    |		disable ngx_http_autoindex_module   **禁用http autoindex module。该模块提供简单的目录浏览功能。**|
|  --without-http_geo_module          |		disable ngx_http_geo_module **禁用http geo module。该模块可以定义一些变量，这些变量的值将与客户端IP地址关联，这样Nginx针对不同的地区的客户端（根据IP地址判断）返回不一样的结果，例如不同地区显示不同语言的网页。**|
|  --without-http_map_module          |		disable ngx_http_map_module **禁用http map module。该模块可以建立一个key/value映射表，不同的key得到相应的value，这样可以针对不同的URL做特殊处理。例如，返回302重定向响应时，可以期望URL不同时返回的Location字段也不一样。**|
|  --without-http_split_clients_module |		disable ngx_http_split_clients_module   **禁用http split clients module。该模块会根据客户端的信息，例如IP地址、header头、cookie等，来区分处理。**|
|  --without-http_referer_module      |		disable ngx_http_referer_module **禁用http referer module。该模块可以根据请求中的refer字段来拒绝请求。**|
|  --without-http_rewrite_module      |		disable ngx_http_rewrite_module **禁用http rewrite module。 该模块提供HTTP请求在Nginx服务内部的重定向功能，依赖PCRE库。**|
|  --without-http_proxy_module        |		disable ngx_http_proxy_module   **禁用http proxy module。 该模块提供基本的HTTP反向代理功能。**|
|  --without-http_fastcgi_module      |		disable ngx_http_fastcgi_module **禁用http fastcgi module。 该模块提供FastCGI功能。**|
|  --without-http_uwsgi_module        |		disable ngx_http_uwsgi_module   **禁用http uwsgi module 该模块提供uWSGI功能。uWSGI是一个Web服务器，它实现了WSGI协议、uwsgi、http等协议。**|
|  --without-http_scgi_module         |		disable ngx_http_scgi_module    **禁用http scgi module 该模块提供SCGI功能。SCGI(Simple Common Gateway Interface),简单通用网关接口。是CGI的替代协议，与FastCGI相似，但更简单。**|
|  --without-http_memcached_module    |		disable ngx_http_memcached_module   **禁用http memcached module。该模块可以使得Nginx直接由上游的memcached服务读取数据，并简单地适配成HTTP响应返回给客户端。**|
|  --without-http_limit_conn_module   |		disable ngx_http_limit_conn_module  **禁用http limit conn module。该模块针对某个IP地址限制并发连接数。**|
|  --without-http_limit_req_module    |		disable ngx_http_limit_req_module   **禁用http limit req module。该模块针对某个IP地址限制并发请求数。**|
|  --without-http_empty_gif_module    |		disable ngx_http_empty_gif_module   **禁用http empty gif module。该模块可以使得Nginx在收到无效请求时，立刻返回内存中的1×1像素的GIF图片。这种好处在于，对于明显的无效请求不会去试图浪费服务器资源。**|
|  --without-http_browser_module      |		disable ngx_http_browser_module **禁用http browser module。该模块会根据HTTP请求中的user-agent字段（该字段通常由浏览器填写）来识别浏览器。**|
|  --without-http_upstream_ip_hash_module|		disable ngx_http_upstream_ip_hash_module    **禁用http upstream ip hash module。该模块提供当Nginx与后端server建立连接时，会根据IP做散列运算来决定与后端哪台server通信，这样可以实现负载均衡。**|
|  --without-http_upstream_least_conn_module|		disable ngx_http_upstream_least_conn_module **禁用http upstream least conn module。该模块提供当Nginx与后端server建立连接时，会通过最少连接负载均衡算法来决定与后端哪台server通信，简单来说就是每次选择的都是当前最少连接的一个server(这个最少连接不是全局的，是每个进程都有自己的一个统计列表)。**|
|  --without-http_upstream_keepalive_module|		disable ngx_http_upstream_keepalive_module  **禁用http upstream keepalive module。这是一个用于nginx的实现缓存的后端连接的keepalive平衡器模块。**|
||
|  --with-http_perl_module            |		enable ngx_http_perl_module|
|  --with-perl_modules_path=PATH      |		set path to the perl modules    **设置perl module的路径，只有使用了第三方的perl module，才需要配置这个路径。**|
|  --with-perl=PATH                   |		set path to the perl binary **设置perl binary的路径。如果配置的Nginx会执行Perl脚本，那么就必须设置此路径。**|
||
|  --http-log-path=PATH               |		set path to the http access log **设置access日志存放路径。**|
|  --http-client-body-temp-path=PATH  |		set path to the http client request body temporary files   **处理HTTP请求时如果请求的包体需要暂时存放到临时磁盘文件中，则把这样的临时文件存放到该路径下。**|
|  --http-proxy-temp-path=PATH        |		set path to the http proxy temporary files  **Nginx作为HTTP反向代理服务器时，上游服务器产生的HTTP包体在需要临时存放到磁盘文件时，这样的临时文件将存放到该路径下。**|
|  --http-fastcgi-temp-path=PATH      |		set path to the http fastcgi temporary files    **设置Fastcgi所使用临时文件的存放路径。**|
|  --http-uwsgi-temp-path=PATH        |		set path to the http uwsgi temporary files  **设置uWSGI所使用临时文件的存放路径。**|
|  --http-scgi-temp-path=PATH         |		set path to the http scgi temporary files   **设置SCGI所使用临时文件的存放路径。**|
||
|  --without-http                     |		disable HTTP server **禁用HTTP服务器。**|
|  --without-http-cache               |		disable HTTP cache  **禁用HTTP服务器里的缓存Cache特性。**|
||
|  --with-mail                        |		enable POP3/IMAP4/SMTP proxy module **安装邮件服务器反向代理模块，使Nginx可以反向代理IMAP、POP3、SMTP等协议，该模块默认不安装。**|
|  --with-mail_ssl_module             |		enable ngx_mail_ssl_module  **安装mail ssl module。该模块可以使IMAP、POP3、SMTP等协议基于SSL/TLS协议之上使用。该模块默认不安装并依赖于OpenSSL库。**|
|  --without-mail_pop3_module         |		disable ngx_mail_pop3_module    **不安装mail pop3 module。在使用--with-mail参数后，pop3 module是默认安装的，以使Nginx支持POP3协议。**|
|  --without-mail_imap_module         |		disable ngx_mail_imap_module    **不安装mail imap module。在使用--with-mail参数后，imap module是默认安装的，以使Nginx支持IMAP协议。**|
|  --without-mail_smtp_module         |		disable ngx_mail_smtp_module    **不安装smtp pop3 module。在使用--with-mail参数后，smtp module是默认安装的，以使Nginx支持SMTP协议。**|
||
|  --with-google_perftools_module     |		enable ngx_google_perftools_module  **启用google perftools module。该模块提供Google的性能测试工具。**|
|  --with-cpp_test_module             |		enable ngx_cpp_test_module  **启用cpp测试模块**|
||
|  --add-module=PATH                  |		enable an external module   **当在Nginx里加入第三方模块时，通过这个参数指定第三方模块的路径。**|
||
|  --with-cc=PATH                     |		set path to C compiler  **设置C编译器的路径**|
|  --with-cpp=PATH                    |		set path to C preprocessor  **设置C预编译器的路径**|
|  --with-cc-opt=OPTIONS              |		set additional options for C compiler   **如果希望在Nginx编译期间指定加入一些编译选项，如指定宏或者使用-I加入某些需要包含的目录，这时可以使用该参数达成目的**|
|  --with-ld-opt=OPTIONS              |		set additional options for linker   **最终的二进制可执行文件是由编译后生成的目标文件与一些第三方库链接生成的，在执行链接操作时可能会需要指定链接参数，--with-ld-opt就是用于加入链接时的参数。例如，如果我们希望将某个库链接到Nginx程序中，需要在这里加入--with-ld-opt=libraryName -LibraryPath，其中libraryName是目标库的名称，LibraryPath则是目标库所在的路径**|
|  --with-cpu-opt=CPU                 |		build for specified CPU, the valid values: pentium, pentiumpro, pentium3, pentium4, athlon, opteron, sparc32, sparc64, ppc64    **指定CPU处理器架构，只能从以下取值中选择：pentium, pentiumpro, pentium3, pentium4, athlon, opteron, sparc32, sparc64, ppc64**|
||
|  --with-make=PATH                   |		specify the default make utility to be used **指定要使用的默认make实用程序**|
||
|  --without-pcre                     |		disable PCRE library usage  **如果确认Nginx不用解析正则表达式，也就是说，nginx.conf配置文件中不会出现正则表达式，那么可以使用这个参数**|
|  --with-pcre                        |		force PCRE library usage    **强制使用PCRE库**|
|  --with-pcre=DIR                    |		set path to PCRE library sources    **指定PCRE库的源码位置，在编译时会进入该目录编译PCRE源码**|
|  --with-pcre-opt=OPTIONS            |		set additional make options for PCRE    **编译PCRE源码时希望加入的编译选项**|
|  --with-pcre-conf-opt=OPTIONS       |		set additional configure options for PCRE   **设置PCRE的其他配置选项**|
|  --with-pcre-jit                    |		build PCRE with JIT compilation support **使用JIT编译支持构建PCRE**|
||
|  --with-md5=DIR                     |		set path to md5 library sources **指定MD5库的源码位置，在编译Nginx时会进入该目录编译MD5源码。注意：Nginx源码中已经有了MD5算法的实现，如果没有特殊需求，那么完全可以使用Nginx自身实现的MD5算法**|
|  --with-md5-opt=OPTIONS             |		set additional options for md5 building **编译MD5源码时希望加入的编译选项**|
|  --with-md5-asm                     |		use md5 assembler sources   **使用MD5的汇编源码**|
||
|  --with-sha1=DIR                    |		set path to sha1 library sources    **指定SHA1库的源码位置，在编译Nginx时会进入该目录编译SHA1源码。注意：OpenSSL中已经有了SHA1算法的实现，如果已经安装了OpenSSL，那么完全可以使用OpenSSL实现的SHA1算法**|
|  --with-sha1-opt=OPTIONS            |		set additional options for sha1 building    **编译SHA1源码时希望加入的编译选项**|
|  --with-sha1-asm                    |		use sha1 assembler sources  **使用SHA1的汇编源码**|
||
|  --with-zlib=DIR                    |		set path to zlib library sources    **指定zlib库的源码位置，在编译Nginx时会进入该目录编译zlib源码。如果使用了gzip压缩功能，就需要zlib库的支持**|
|  --with-zlib-opt=OPTIONS            |		set additional options for zlib building    **编译zlib源码时希望加入的编译选项**|
    |  --with-zlib-asm=CPU                |		use zlib assembler sources optimized  for specified CPU, the valid values:pentium, pentiumpro    **指定对特定的CPU使用zlib库的汇编优化功能，目前仅支持两种架构：pentium和pentiumpro**|
||
|  --with-libatomic                   |		force libatomic_ops library usage   **强制使用atomic库。atomic库是CPU架构独立的一种原子操作的实现。它支持以下体系架构：x86（包括i386和x86_64）、PPC64、Sparc64（v9或更高版本）或者安装了GCC4.1.0及更高版本的架构。**|
|  --with-libatomic=DIR               |		set path to libatomic_ops library sources   **atomic库所在的位置**|
||
|  --with-openssl=DIR                 |		set path to OpenSSL library sources **指定OpenSSL库的源码位置，在编译Nginx时会进入该目录编译OpenSSL源码。 注意：如果Web服务器支持HTTPS，也就是SSL协议，Nginx要求必须使用OpenSSL。可以访问http://www.openssl.org/免费下载**|
|  --with-openssl-opt=OPTIONS         |		set additional options for OpenSSL building **编译OpenSSL源码时希望加入的编译选项**|
||
|  --dry-run                          |		dry running the configure, for testing only **仅测试配置**|
|  --platform=PLATFORM                |		forcibly specify a platform name, for testing only  **强制指定平台名称，仅用于测试**|
||





