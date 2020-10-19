#!/bin/sh

SRC="$*"


if test -z "$SRC"
then
    SRC=`ls -d -C1 src/ radical/ examples/ test 2>/dev/null`
fi

if test -z "$SRC"
then
    SRC='.'
fi

for src in $SRC
do
    echo "checking in $src"
    for f in `find $src -name '*.py'`
    do
        echo "  $f"
        pylint $f 2>&1 | grep -e '^[EF]:'
    done
    echo
done


