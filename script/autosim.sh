#!/bin/bash
#automatically elaborate TB structure and start simulation
#USAGE: bash ./script/autosim.sh $(TB_MODULE) $(TB_DIR) $(INCLUDE_DIR) $(REPORT_FILENAME) $(RTL_DIR) $(OBJ_DIR)

#elaborate TB hierarchy
bash ./script/elaborate.sh $1 $2 $3 $4 &> ./temp/tb_elaborate.log
if ! test -s ./temp/elaborate_error;
then
    echo "TB elaborate failed!"
    exit -1
else #此处假定缺乏的模块一定是DUT
    RTL=$(cat ./temp/elaborate_error|sed '2,$d')
    bash ./script/elaborate.sh $RTL $5 $3 /tmp/tb_rtlscan >>./temp/tb_elaborate.log
    if test -e ./temp/elaborate_error;
    then
        echo "DUT elaborate failed!"
        exit -1
    fi
fi
rm ./temp/elaborate_error &>/dev/null
#extract PREPROCESSOR
#still buggy
cat $4 |sed '2,$d'|xargs sed 's/$/!END!/g'|xargs|\
sed 's/^.*\#PREPROCESS_START //g' | sed 's/\#PREPROCESS_END.*$//g' |\
sed 's/!END!/\n/g'


#exit
bash ./temp/PREPROCESSOR.sh
#run
cat $4|xargs iverilog -o $6/tb.run -I $3
vvp $6/tb.run
