#! /bin/bash
#！ -*- coding=utf-8 -*-
# Author:zhouze03
# Date: 2017-08-16


##############################################################################################
##########################################  main #############################################
##############################################################################################


function start() {

	# 设置贪婪脚本的执行进程不会独占一个CPU逻辑单元，因为贪婪脚本中有无限循环（不设置则独占一个逻辑单元）
	nohup ./cpulimit -l 50 ./cpu_scheduler.sh -e $EXPECT_CPU_RATE -l $CPU_LIMIT_FOR_GREEDY_PROCESS  >/dev/null &
}


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
        # 用户没有输入，则提供默认值
        CPU_LIMIT_FOR_GREEDY_PROCESS=60
    fi

    if [ $CPU_LIMIT_FOR_GREEDY_PROCESS -lt 0 -o $CPU_LIMIT_FOR_GREEDY_PROCESS -gt 100 ]
    then
        echo "PARAM ERROR: CPU_LIMIT_FOR_GREEDY_PROCESS value expect [1-100] (-e)" >&2
        exit -1
    fi


}




while getopts "e:l:" opt
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
start

##############################################################################################
##############################################################################################
##############################################################################################
