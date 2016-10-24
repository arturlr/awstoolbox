#!/bin/bash

# Check parameters
if [[ ! -n "$1" ]] || [[ "$#" -gt "3" ]]; then
  echo "Use: strfilereplace filename regular-expression replacement-string"
  exit 1
fi

if [[ ! -f "$1" ]]; then
    echo 'Wrong filename input'
    exit 1
fi

count=0
countReplacements=0
re="$2"
replacement="$3"
filename="$1"
while read -r line
do
   (( count++ ))
   if [[ "$line" =~ $re ]]; then
      matchString=`echo $line | grep -E -o "$2"`
      echo "Replacing $matchString on line $count for $3"
      (( countReplacements++ ))
   fi
done < "$filename"

if [[ "$countReplacements" -gt 0 ]]; then
   sed -i -E s/"$2"/"$3"/g "$filename"
else
   echo "No matches found."
fi
