#!/bin/bash

# Check parameters
if [[ ! -n "$1" ]] || [[ "$#" -gt "3" ]]; then
  echo "Use: portscan servername start-port [end-port]"
  echo "bash1 192.168.0.1 3000 3500"
  echo "bash1 www.google.com 80"
  exit 1
fi

if !  [[ $1 =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
   alive=`dig +short "$1"`
   if [[ ! -n "$alive" ]]; then
     echo "Host $1 cannot be resolved"
     exit 1
   fi
fi

sPort="$2"
if [[ ! -n "$3" ]]; then
   ePort="$2"
else
   ePort="$3"
fi

# Check if the ports parameters are numbers
re='^[0-9]+$'
if ! [[ "$sPort" =~ $re ]] || ! [[ "$ePort" =~ $re ]] || [[ "sPort" -gt 65535 ]]
 ; then
   echo "error: Invalid port"
   exit 1
fi
if [[ "$sPort" -gt "$ePort" ]]; then
   echo "Start port has to be lower than the end port or port is not valid"
   exit 1
fi

output=`netcat -v -z -w 1 "$1" "$sPort"-"$ePort"`

echo $output
