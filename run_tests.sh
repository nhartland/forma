#!/bin/bash
# Runs test suite, including luacov coverage report
# Requirements:
#       luaunit
#       luacov

# Run luaunit tests
if ! lua tests/run.lua -o TAP
then
    exit 1
fi

echo "Running examples"
for example in ./examples/*.lua; do
    if !  lua "$example" > /dev/null
    then
        echo "$example fails"
        exit 1
    else
        echo "$example passes"
    fi
done

exit 0
