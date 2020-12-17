#!/bin/bash
rm ./temp/lint_error >&/dev/null
cat ./temp/hierarchy.rpt | xargs iverilog -o /dev/null -I $1 >& /tmp/lint.log
cat /tmp/lint.log | sed -n '/error/p' |sort -k2n |uniq >./temp/lint_errors.rpt
cat /tmp/lint.log | sed -n '/warning/p'|sort -k2n |uniq >./temp/lint_warnings.rpt
cat /tmp/lint.log
echo -e "\033[33m==================LINT WARNING REPORT====================\033[0m"
cat ./temp/lint_warnings.rpt
if test -s ./temp/lint_errors.rpt; 
then
    echo -e "\033[31m==================LINT ERROR REPORT====================\033[0m"
    cat ./temp/lint_errors.rpt
    echo >./temp/lint_error
else
    echo -e "\033[32mNo Error found in linting process, Flow can move forward\033[0m"
fi