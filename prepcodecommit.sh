#!/bin/bash

if [[ ! -n "$1" ]]; then
   echo "Please add the project name"
   exit 1
fi

read curdir <<< $(pwd)

aws codecommit create-repository --repository-name $1 --repository-description "$1 Lambda Function" --profile devprofile

cd "${curdir}"/$1

git init
git config --global user.email "xxxxx@xxxxx.com"
git config --global user.name "devprofile"
git remote add origin ssh://git-codecommit.[region].amazonaws.com/v1/repos/$1
git add *
git commit -m "Inital commit"
git push origin master
