#!/bin/bash
cat ./temp/hierarchy.rpt | xargs iverilog -I $1 >& /tmp/lint.log
cat /tmp/lint.log | sed -n '/error/p' >./temp/lint_errors.rpt
cat /tmp/lint.log | sed -n '/warning/p' >./temp/lint_warnings.rpt
cat ./temp/lint_warnings.rpt
cat ./temp/lint_errors.rpt