#! /bin/bash
#！ -*- coding=utf-8 -*-
# Author:zhouze03
# Date: 2017-08-15


#############
# 该脚本用于测试的目的，测试当有CPU% 已经超过期望的值时（这里由自己决定，比如KG机器希望CPU超50%，那么此值即50）
# cpu_schedule.sh 的脚本逻辑是否会判断当前检测时刻CPU负载达标，从而不会去启动贪婪进程。
# 操作&&简而言之：
# 确定该脚本需要启用多少个贪婪进程，这个需要使用者自己根据CPU的逻辑核数目去计算，
# 比如48核，在没有任何其它CPU消耗的情况下，需要启用大概 48 * 50% = 24 个贪婪进程（下面脚本固定控制为单CPU逻辑单元使用为 95%）
# 备注：
# 视当前测试机器CPU 现有占用百分值去计算。
# 测试目标：
# 上述进程确定并启动后，使用htop进行观察，cpu_scheduler 应该判断出当前CPU已经达到指标值，从而它不会启动它要调用的贪婪进程。
# 目标符合预期则：
#  cpu_scheduler.sh 程序能根据机器CPU自适应的调节贪婪进程的启动数目。	
############



function fire_greedy_process(){
        for i in `seq 1 22`
        do
        {
                echo "start greedy process "$i
                # 贪婪进程
                ./cpulimit -l 95 bash ./test_dead_circle.sh >/dev/null &
        }
        done
}

FLAG=0

while true
do
        if [ $FLAG -eq 0 ]; then
                echo "FLAG="$FLAG
                fire_greedy_process
                FLAG=1
        fi

done