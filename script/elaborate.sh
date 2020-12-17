#!/bin/bash
#elaborate RTL structure
#USAGE: bash ./script/elaborate.sh $(TOP_MODULE) $(RTL_DIR) $(INCLUDE_DIR) $(REPORT_FILENAME)
#RELY ON: iverilog 
rm $4 >&/dev/null #Prep begin
rm ./temp/elaborate_error >&/dev/null
echo 123123 > /tmp/module_missing_prev.log #Prep end

find $2 -name "*.v" >/tmp/scan.out #找到全部源代码
cat /tmp/scan.out | xargs grep "module \<$1\>" |sed 's/\:module.*$//g' >>$4   #寻找顶层模块，并写入hierarchy.rpt
if ! test -s $4; 
then
    echo -e "\033[31mFatal:Top level module NOT EVEN EXIST! ELABORATE FAILED! \033[0m"
    echo > ./temp/elaborate_error
    exit
fi

for i in `seq 50`;#广度优先搜索
do
    cat $4|xargs iverilog -o /dev/null -I $3 2>&1|sed -n '/Unknown\ module\ type/p'| sed 's/^.*type:\ //g' >/tmp/module_missing.log #综合缺模块不？
    if ! test -s /tmp/module_missing.log; 
    then
        echo -e "\033[32mElaborate target $1 Successfully finished in $i passes, no error found\033[0m"
        break #没有找不到的模块就完成
    else
        TEST=$(diff /tmp/module_missing.log /tmp/module_missing_prev.log| xargs echo) #&>/dev/null
        if ! test -n "$TEST" >>/dev/null ; 
        then
            echo -e "\033[31mError: Some modules are always missing, consider some error found?\033[0m"
            echo -e "\033[31mMissing (or error) Modules are:\033[0m"
            cat /tmp/module_missing.log
            echo > ./temp/elaborate_error
            echo -e "\033[33m================Lint Result=================\033[0m"
            cat $4 | xargs iverilog -o /dev/null -I $3
            break
        else
            echo -e "\033[32mMore modules found compared with scan #$i, No problem\033[0m"
        fi
    fi
    echo >/tmp/module_curr_layer.log
    cat /tmp/module_missing.log | while read line
    do
        cat /tmp/scan.out | xargs grep "module \<$line\>" |sed 's/\:module.*$//g' >> /tmp/module_curr_layer.log  #寻找所有模块中的xx模块，并写入hierarchy.rpt
    done
    cat /tmp/module_curr_layer.log|sort -k2n |uniq >>$4
    mv -f /tmp/module_missing.log /tmp/module_missing_prev.log
    
done
#cat $4 | xargs iverilog -o /dev/null -I $3
