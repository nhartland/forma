for example in ./examples/*.lua; do
    lua "$example" > /dev/null
    if [ $? -ne 0 ]; then
        echo "$example fails"
        exit $?
    else
        echo "$example passes"
    fi
done
