#!/bin/bash

# Check parameters
if [[ ! -n "$1" ]] || [[ "$#" -gt "3" ]]; then
  echo "Use: strfileinsert filename line_number string"
  echo "This script inserts a string at the first occurence of line_number and a
ll increments until the of file"
  exit 1
fi

if [[ ! -f "$1" ]]; then
    echo 'Wrong filename input'
    exit 1
fi
# Check if the ports parameters are numbers
re='^[0-9]+$'
if ! [[ "$2" =~ $re ]]; then
   echo "error: Invalid line number"
   exit 1
fi


function MessupFile()
{
    if ! [[ -f "$3" ]]; then
       echo "File $3 does not exist"
       exit 1
    fi

    re='^[0-9]+$'
    if ! [[ "$2" =~ $re ]]; then
       echo "Not a valid number"
       exit 1
    fi

    newtext="$1"
    seed="$2"
    linecount="$2"
    filename="$3"
    count=0

    if [[ -f ~/messup.tmp ]]; then
       rm ~/messup.tmp
    fi

    while read -r line
    do
      (( count++ ))
       if [[ "$count" == "$linecount" ]]; then
          echo "$newtext" >> ~/messup.tmp
          linecount=$((linecount + seed - 1))
       fi
       echo "$line" >> ~/messup.tmp
    done < "$filename"
    mv $filename "$filename.orig"
    mv ~/messup.tmp $filename
    echo "Done."
    echo "Original file at $filename.orig"
}

# Starts here

MessupFile "$3" "$2" "$1"
