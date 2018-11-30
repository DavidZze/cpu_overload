


### Release Note:
* v0.0.1 : CPU多核Linux CentOS的整体CPU%达到指定的值。




### 说明：
该应用脚本是为了提高机器的CPU使用率，它会根据当前机器CPU （会自动排除本程序进程所占用CPU%） 决定是否需要”协助“已提高当前机器的CPU的使用率；
1. 当前脚本会自动的去判断当前机器的CPU逻辑单元数目；
2. 脚本的检查周期为 1min；
3. 具备自动调节能力，会自动计算以达到用户指定的总CPU% 占有率；（当前脚本CPU%（自动调节，调节周期1min） + 其它进程CPU% 约等于= 用户目标总CPU%）
备注：
1. 不要去更改脚本的相对路径，所有脚本都得按照我提供的路径（平级）存放，因为脚本中使用的时相对路径进行脚本间的调用；
2. 提供了test 脚本，用于测试cpu_scheduler 程序能否自适应，使用者可以自行学习验证；
3. cpulimit 只能在Linux CenOS上使用，如果需要在其它平台使用，则需要根据（c++源文件重新编译）;
 * 3.1 unzip cpulimit.zip
 * 3.2 cd cpulimit-master
 * 3.3 make
 * 3.4 copy src/cpulimit 到当前应用目录


### 启动命令（推荐）：
```bash
$ cd ${cpu_greeedy目录}
$ ./start_kg_cpu_control.sh -e 50
或者
$ ./start_kg_cpu_control.sh -e 50 -l 50
```

### 终止命令：
```bash
$ cd ${cpu_greeedy目录}
$ ./stop_kg_cpu_control.sh

备注:
-e: 表示希望机器达到的总CPU% 占用率;
-l: 表示我提供的脚本进程, "贪婪进程"对单个CPU逻辑单元的占用率, 推荐60. 避免过高独占一个完整的CPU逻辑单元而降低CPU的并发度.
```






