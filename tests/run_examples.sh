for example in ./examples/*.lua; do
    if ! lua "$example" > /dev/null
    then
        echo "$example fails"
        exit 1
    else
        echo "$example passes"
    fi
done
