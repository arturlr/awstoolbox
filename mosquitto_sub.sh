#!/bin/sh
p="mqttPipe"
([ ! -p "$p" ]) && mkfifo $p
(mosquitto_sub --cert /etc/iot/aws.certificate.pem --key /etc/iot/aws.private.pem.key --cafile /etc/iot/root.cer -h aaaaaaaaaaaaaaaa.iot.us-west-2.
amazonaws.com -p 8883 -q 1 -d -t inetbutton/all -v >$p 2>/dev/null) &
PID=$!

trap 'kill $PID' HUP INT TERM QUIT KILL

while read line <$p
do
   echo $line > /tmp/cmds
   if grep -q "clickType" /tmp/cmds
   then
      CLICK=`cat /tmp/cmds | awk -F'"' '$0=$4'`
      # echo $CLICK
      if [ "$CLICK" == "SINGLE" ]; then
         /etc/iot/internet-off.sh
      elif [ "$CLICK" == "DOUBLE" ]; then
         /etc/iot/internet-on.sh
      else
         /etc/iot/resetfw.sh > /dev/null 2>&1
      fi
      echo "Event: " $line
   fi
done
