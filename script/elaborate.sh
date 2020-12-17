#!/bin/bash
#elaborate structure
#USAGE: bash ./script/elaborate.sh $(TOP_MODULE) $(RTL_DIR) $(INCLUDE_DIR)
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
    cat ./temp/hierarchy.rpt|xargs iverilog -I $3 2>&1|sed -n '/Unknown\ module\ type/p'| sed 's/^.*type:\ //g' >/tmp/module_missing.log #综合缺模块不？
    if ! test -s /tmp/module_missing.log; 
    then
        echo "Elaborate target $1 Successfully finished in $i passes, no error found"
        break #没有找不到的模块就完成
    else
        TEST=$(diff /tmp/module_missing.log /tmp/module_missing_prev.log| xargs echo) #&>/dev/null
        if ! test -n "$TEST" >>/dev/null ; 
        then
            echo "Error: Some modules are always missing, consider some error found?"
            echo > ./temp/elaborate_error
            break
        else
            echo "More modules found compared with scan #$i, No problem"
        fi
    fi
    echo >/tmp/module_curr_layer.log
    cat /tmp/module_missing.log | while read line
    do
        cat /tmp/scan.out | xargs grep "module \<$line\>" |sed 's/\:module.*$//g' >> /tmp/module_curr_layer.log  #寻找所有模块中的xx模块，并写入hierarchy.rpt
    done
    cat /tmp/module_curr_layer.log|sort -k2n |uniq >>./temp/hierarchy.rpt
    mv -f /tmp/module_missing.log /tmp/module_missing_prev.log
    
done
#cat ./temp/hierarchy.rpt | xargs iverilog -I $3
