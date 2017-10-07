#!/bin/bash

if [[ ! -n "$1" ]]; then
   echo "Please add the project name"
   exit 1
fi

DATE_SUFFIX=$(date +%y%m%d-%H%M)
DATE_TICKS=$(date +%s)
TICK_SUFFIX=${DATE_TICKS:6:4}

cd $1

git add .
git commit -m "v$DATE_SUFFIX"
git push origin master

cd ..

echo "v$DATE_SUFFIX"
