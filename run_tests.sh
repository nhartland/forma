#!/bin/bash
# Runs test suite, including luacov coverage report
# Requirements:
#       luaunit
#       luacov
LUA=luajit

echo "Running luaunit tests"
$LUA -lluacov tests/run.lua -o TAP
echo "Generating luacov report"
luacov && rm luacov.stats.out 

echo "Running examples"
for example in ./examples/*.lua; do
    $LUA "$example" > /dev/null
    RETVAL=$?
    if [ $RETVAL -ne 0 ]; then
        echo "$example fails"
    else
        echo "$example passes"
    fi
done
