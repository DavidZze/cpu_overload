#! /bin/bash
#！ -*- coding=utf-8 -*-
# Author:zhouze03
# Date: 2017-08-15

######
# 期望当正经的CPU%使用率 <  期望值时 ; 可以启动额外的任务来提升CPU的使用率；
# 备注：
# 1. 当前程序作为附加程序，要做到”不得已而用之“；
# 2. 本程序会调用一个非常消耗CPU的脚本程序：这个进程暂且称之为”greedy（贪婪的）进程“（死循环脚本）
# 3. 服务器其它的进程都认为是online的进程；
######

# 1. 当前CPU总使用率（排除/kill贪婪进程）；（CURR_CPU_RATE）
# 2. 某进程CPU总使用率：（greedy_process_cpu_rate）（舍弃）
# 3. 期望的CPU% 使用百分值；(EXPECT_CPU_RATE)
# 4. 逻辑CPU的个数 CPU_LOGI_NUM

############
# 算法：
# 无限循环语句：
# 0. 每5分钟检查一次；
# 1. 由于当前的进程CPU使用率不好获取，因此，使用直接kill贪婪进程的方式（如果有进程），然后获取此刻的CPU使用率（该使用率 = 正经CPU使用率）
# 2. 获取当前的CPU% 使用率；
# 3. 获取贪婪值：GREEDY_VALUE=(EXPECT_CPU_RATE - CURR_CPU_RATE)
# Case1: GREEDY_VALUE > 0; then
#	 	本次贪婪占用核数目 =（CPU核数目 * 贪婪值（0.0-1））向下取整  && 启动与贪婪核数目相同的进程数目；（通过cpulimit 限制贪婪进程最高占用95%CPU）
# 备注：
# 使用cpulimit 只运行单进程对单核的使用上限为95% 是为了避免超过100%不可预期的异常。（不确定超过100% 是否会造成问题，因此保险起见进行了限制）
# 其次，线程可控，该程序脚本的线程上限为CPU的核数目，不会为了打满CPU而创建过的线程的情况，（Linux 用户线程有上限，避免影响线上（正经）的服务）
# 备注（重点）：
# 单个贪婪进程所占用的CPU% ：
# 1. 如果当前机器总CPU% < 50%;  then: 可以使得单贪婪进程CPU% > 80%; (如果一半的CPU逻辑单元被占满不会影响其它服务可以这样设置，否则按下面的方式)
# 2. 如果当前服务器上正经的服务对CPU逻辑单元需求很大，则设置单个贪婪进程CPU% <= 50% , 同时贪婪进程个数增加，
#	 这样虽在表面上看起来两个50% 的进程占用了100%，但是在CPU的并发度上是不同的，其它的进程有机会去获取CPU时间片去执行它们的程序；
# 简而言之：
#  CPU_LIMIT_FOR_GREEDY_PROCESS 确定了贪婪进程的个数与进程所占的比例
############


# 设定期望值(改为main参数确定)
# EXPECT_CPU_RATE=50
# 贪婪进程比例的设定 (改为main参数确定)
# CPU_LIMIT_FOR_GREEDY_PROCESS=50

# 当前CPU%
function get_curr_cpu_rate(){
	local curr_cpu_rate=`env LC_ALL=en_US.UTF8 sar 1 1 | grep ^Average | awk '{print $8}' `
	curr_cpu_rate=${curr_cpu_rate%.*}
	CURR_CPU_RATE=`expr 100 - $curr_cpu_rate`
	echo "CURRENT CPU USAGE RATE="$CURR_CPU_RATE
}

# 当前机器 逻辑CPU数目
function get_cpu_logi_num(){
	CPU_LOGI_NUM=`cat /proc/cpuinfo| grep "processor"| wc -l`
	echo "CPU LOGI NUM="$CPU_LOGI_NUM
}

# kill 贪婪进程
function kill_greedy_pid(){
	 ps -ef | grep ./dead_circle.sh | grep -v grep | awk '{print $2}' | xargs kill -9 > /dev/null
}

# 贪婪start
function fire_greedy_process(){
	echo "GREEDY NUM= "$1
	for i in `seq 1 $1`
	do
	{
		./cpulimit -l $CPU_LIMIT_FOR_GREEDY_PROCESS  bash ./dead_circle.sh > /dev/null &
	}
	done
}

##############################################################################################
#####################################  贪婪引擎  ##############################################
##############################################################################################

function greedy_machine(){
	# 确定CPU核数目：
	get_cpu_logi_num

	# 贪婪调度器
	while true
	do
		# 1.kill 贪婪进程
		kill_greedy_pid
		# 2.获取当前CPU%
		get_curr_cpu_rate
		# 3.获取贪婪值
		GREEDY_VALUE=`expr $EXPECT_CPU_RATE - $CURR_CPU_RATE`
		echo "GREEDY_VALUE="$GREEDY_VALUE
		# 4.是否执行贪婪计划
		if [ $GREEDY_VALUE -gt 0 ]; then
			# 确定贪婪进程数
			# greedy_process_num=`expr $CPU_LOGI_NUM \* $GREEDY_VALUE / 100`
			greedy_process_num=`expr $CPU_LOGI_NUM \* $GREEDY_VALUE / $CPU_LIMIT_FOR_GREEDY_PROCESS`
			GREEDY_PROCESS_NUM=${greedy_process_num%.*}
			echo "GREEDY_PROCESS_NUM= "$GREEDY_PROCESS_NUM
			# 大于0则调度
			if [ $GREEDY_PROCESS_NUM -gt 0 ]; then
				fire_greedy_process $GREEDY_PROCESS_NUM
			fi
		fi
		# 休眠1min
		sleep 60
	done
}

##############################################################################################
##############################################################################################
##############################################################################################




##############################################################################################
##########################################  main #############################################
##############################################################################################


function check_parameters(){

    if [ "x$EXPECT_CPU_RATE" == "x" ]
    then
        echo "PARAM ERROR: EXPECT_CPU_RATE IS NULL (-e)" >&2
        exit -1
    fi

 	if [ $EXPECT_CPU_RATE -lt 0 -o $EXPECT_CPU_RATE -gt 100 ]
    then
        echo "PARAM ERROR: EXPECT_CPU_RATE value expect [1-100] (-e)" >&2
        exit -1
    fi

    if [ "x$CPU_LIMIT_FOR_GREEDY_PROCESS" == "x" ]
    then
        echo "PARAM ERROR: CPU_LIMIT_FOR_GREEDY_PROCESS IS NULL (-l)"
        exit -1
    fi

    if [ $CPU_LIMIT_FOR_GREEDY_PROCESS -lt 0 -o $CPU_LIMIT_FOR_GREEDY_PROCESS -gt 100 ]
    then
        echo "PARAM ERROR: CPU_LIMIT_FOR_GREEDY_PROCESS value expect [1-100] (-e)" >&2
        exit -1
    fi


}




while getopts "e:l:h" opt
do
    case $opt in
        e)
            EXPECT_CPU_RATE=$OPTARG
            echo "EXPECT_CPU_RATE= "$EXPECT_CPU_RATE
        ;;
        l)
            CPU_LIMIT_FOR_GREEDY_PROCESS=$OPTARG
            echo "CPU_LIMIT_FOR_GREEDY_PROCESS= "$CPU_LIMIT_FOR_GREEDY_PROCESS
        ;;
        *)
            echo "ERROR don't support this parameter" >&2
            usage
            exit -1
        ;;
    esac
done

check_parameters
greedy_machine


##############################################################################################
##############################################################################################
##############################################################################################



