#!/bin/bash
#elaborate structure
rm ./temp/hierarchy.rpt >&/dev/null
rm ./temp/elaborate_error >&/dev/null
echo 123123 > /tmp/module_missing_prev.log 
find $2 -name "*.v" >/tmp/scan.out #找到全部源代码
cat /tmp/scan.out | xargs grep "module \<$1\>" |sed 's/\:module.*$//g' >>./temp/hierarchy.rpt   #寻找顶层模块，并写入hierarchy.rpt
if ! test -s ./temp/hierarchy.rpt; 
then
    echo "Fatal:Top level module NOT EVEN EXIST!"
    echo > ./temp/elaborate_error
    exit
fi

for i in `seq 50`;#广度优先搜索
do
    cat ./temp/hierarchy.rpt|xargs iverilog -I $3 2>&1|sed -n '/Unknown\ module\ type/p'| sed 's/^.*type:\ //g' |sort -k2n |uniq >/tmp/module_missing.log #综合缺模块不？
    
    #echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
    #cat ./temp/hierarchy.rpt|xargs iverilog -I $3
    #cat /tmp/module_missing.log|sort -k2n |uniq >/tmp/module_missing.log
    if ! test -s /tmp/module_missing.log; 
    then
        echo "Elaborate Successfully finished, no error found"
        break #没有找不到的模块就完成
    else
        TEST=$(diff /tmp/module_missing.log /tmp/module_missing_prev.log| xargs echo) #&>/dev/null
        if ! test -n "$TEST" >>/dev/null ; 
        then
            echo "Error: Some modules are always missing, consider some error found?"
            echo > ./temp/elaborate_error
            #cat ./temp/hierarchy.rpt |xargs iverilog -I $3 
            break
        else
            echo "More modules found compared with scan #$i, No problem"
        fi
    fi
    #cat /tmp/module_missing.log 
    #nl /tmp/module_missing.log | sort -u | cut -f2 >/tmp/module_missing.log
    cat /tmp/module_missing.log | while read line
    do
        cat /tmp/scan.out | xargs grep "module \<$line\>" |sed 's/\:module.*$//g' >>./temp/hierarchy.rpt   #寻找所有模块中的xx模块，并写入hierarchy.rpt
    done
    mv -f /tmp/module_missing.log /tmp/module_missing_prev.log
    
done
#cat ./temp/hierarchy.rpt |sort -u
#cat ./temp/hierarchy.rpt|sort -k2n |uniq >./temp/synthesis.out
cat ./temp/hierarchy.rpt | xargs iverilog -I $3
