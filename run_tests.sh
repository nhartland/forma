#!/bin/bash
LUA=luajit

echo "Running luaunit tests"
for test in ./tests/*.lua; do
    $LUA "$test"
done

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
