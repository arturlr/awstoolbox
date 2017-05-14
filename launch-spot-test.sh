#!/bin/bash

USERDATA=`cat userdata.win | base64 -w0`

imageid=ami-xxxx
ec2key=nameofthekey
securitygroup=sg-xxxx
instancetype=m3.medium
subnetid=subnet-xxx
ec2role=nameoftherole
keyvalue=name
keyname=blabla


echo "{\"ImageId\": \"$imageid\",\"UserData\": \"string\",\"KeyName\": \"$ec2key\",\"SecurityGroupIds\": [ \"$securitygroup\" ],\"InstanceType\": \"$instancetype\",\"SubnetId\": \"$subnetid\",\"UserData\": \"$USERDATA\"}" > spotspec.json

aws ec2 request-spot-instances --spot-price "0.06" --instance-count 1 --type "one-time" --launch-specification file://spotspec.json > spot-request.txt

requestid=`cat "spot-request.txt" | grep SpotInstanceRequestId | cut -d':' -f2 | sed 's/[^0-9A-Za-z/+=]*//g'`
DASH="-"
requestid_formatted=${requestid:0:3}$DASH${requestid:3}
echo "Spot Request Id: ${requestid_formatted}"
while true;
do
    echo 'Waiting 30 sec for the spot to be fulfilled...'
    aws ec2 describe-spot-instance-requests --filter Name=spot-instance-request-id,Values="${requestid_formatted}" > spot-status.log
    status=`cat spot-status.log | grep Code | cut -d':' -f2 | sed 's/[^0-9A-Za-z/+=]*//g'`
    echo "Status: ${status}"
    if [ "$status" == 'fulfilled' ]; then
        instanceid=`cat spot-status.log | grep InstanceId | cut -d':' -f2 | sed 's/[^0-9A-Za-z/+=]*//g'`
        instanceid_formatted=${instanceid:0:1}$DASH${instanceid:1}
        echo "Instance: ${instanceid_formatted}"
        aws ec2 create-tags --resources ${requestid_formatted} ${instanceid_formatted} --tags Key="$keyname",Value="$keyvalue"
        aws ec2 associate-iam-instance-profile --instance-id ${instanceid_formatted} --iam-instance-profile Name="$ec2role"
        break
    fi
    sleep 30

    COUNT=$[$COUNT + 1]
    if (("$COUNT" > "5")); then
       echo 'Timing out...'
       break
    fi
done
