#!/bin/bash
#

cd /data/hexo_blog/
git reset --hard
git pull origin master  
hexo generate
