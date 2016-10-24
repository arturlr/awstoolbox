#!/usr/bin/python

# This script list all your running ec2instances and check the status of the volumes attached.

from __future__ import print_function
from sets import Set

import boto3
import json

print('Loading function')

ec2client = boto3.client('ec2','us-east-1')
ec2resource = boto3.resource('ec2','us-east-1')

statDict = {}

response = ec2client.describe_instances()
for reservation in response["Reservations"]:
    for instance in reservation["Instances"]:
	state=instance['State']['Name']
        if state == 'running':
            statDict[instance['InstanceId']] = {}
	    for volume in instance["BlockDeviceMappings"]:
                if 'Ebs' in volume:
                    volumeid = volume['Ebs']['VolumeId']
                    ebsvolume = ec2resource.Volume(volumeid)
                    if (ebsvolume.state == "in-use"):
		        rsp = ebsvolume.describe_status()
		        stat = rsp["VolumeStatuses"][0]["VolumeStatus"]["Status"]
                        statDict[instance['InstanceId']][volumeid] = stat

print (statDict)
