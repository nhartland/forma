#!/bin/bash
# Runs test suite, including luacov coverage report
# Requirements:
#       luaunit
#       luacov

LUA=${LUA:=luajit}

# Run luaunit tests
$LUA -lluacov tests/run.lua -o TAP
if [ $? -ne 0 ]; then
    exit $?
fi

# Generate luacov report
luacov && rm luacov.stats.out 

echo "Running examples"
for example in ./examples/*.lua; do
    $LUA "$example" > /dev/null
    if [ $? -ne 0 ]; then
        echo "$example fails"
        exit 1
    else
        echo "$example passes"
    fi
done

exit 0
