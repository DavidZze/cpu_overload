#! /bin/bash
#！ -*- coding=utf-8 -*-
# Author:zhouze03
# Date: 2017-08-16


# kill 主线程
ps -ef | grep ./cpu_scheduler.sh | grep -v grep | awk '{print $2}' | xargs kill -9

# 为了安全起见kill 贪婪进程（正常情况kill 主线程，子线程即退出）
ps -ef | grep ./dead_circle.sh | grep -v grep | awk '{print $2}' | xargs kill -9


# 测试脚本相关
# ps -ef | grep ./test_dead_circle.sh | grep -v grep | awk '{print $2}' | xargs kill -9