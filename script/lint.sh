#!/bin/bash
cat ./temp/hierarchy.rpt | xargs iverilog -I $1 >& /tmp/lint.log
cat /tmp/lint.log | sed -n '/error/p' |sort -k2n |uniq >./temp/lint_errors.rpt
cat /tmp/lint.log | sed -n '/warning/p'|sort -k2n |uniq >./temp/lint_warnings.rpt
cat /tmp/lint.log
echo "==================WARNING REPORT===================="
cat ./temp/lint_warnings.rpt
echo "==================ERROR REPORT===================="
cat ./temp/lint_errors.rpt