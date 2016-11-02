#!/usr/bin/python
from __future__ import print_function
import boto3
import sys
import csv

# Account that you want to pull information from
awsAccounts = {'000000000','000000000'}


# User credentials that will execute this script
ec2Regions = boto3.client(
    'ec2',
    aws_access_key_id = "AKIA",
    aws_secret_access_key = "B1Jr"
).describe_regions()['Regions']

stsclient = boto3.client(
    'sts',
    aws_access_key_id = "AKIA",
    aws_secret_access_key = "B1Jr"
)

s3 = boto3.resource(
    's3',
    aws_access_key_id = "AKIA",
    aws_secret_access_key = "B1Jr"
)

finstance = open('instances.csv', 'wt')
writerinstance = csv.writer(finstance)
writerinstance.writerow(('acct', 'instanceid', 'type', 'platform', 'region', 'az', 'vpcid', 'rootdevice', 'ebsopt', 'eip', 'role'))

frds = open('rds.csv', 'wt')
writerrds = csv.writer(frds)
writerrds.writerow(('acct', 'instancetype', 'multiaz', 'storagetype','endpoint','az'))

febs = open('ebs.csv', 'wt')
writerebs = csv.writer(febs)
writerebs.writerow(('acct', 'volid', 'az', 'instanceId','attstate','type','size','state','encrypted'))

for acct in awsAccounts:
    for regionObj in ec2Regions:
        try:
	    # Role that the user that executes this script belongs in all the accounts he is pulling information
	    # For this script to work the Role name has to be inventory-Role-RO 
	    # The role has to grant Read-Only access to EC2 and RDS services
            region = regionObj['RegionName']
            assumedRole = stsclient.assume_role(
                RoleArn="arn:aws:iam::" + acct + ":role/inventory-Role-RO",
                RoleSessionName="AssumeRole" + acct
            )

            credentials = assumedRole['Credentials']

            ec2client = boto3.client(
                'ec2',
                region_name=region,
                aws_access_key_id=credentials['AccessKeyId'],
                aws_secret_access_key=credentials['SecretAccessKey'],
                aws_session_token=credentials['SessionToken']
            )

            rdsclient = boto3.client(
                'rds',
                region_name=region,
                aws_access_key_id=credentials['AccessKeyId'],
                aws_secret_access_key=credentials['SecretAccessKey'],
                aws_session_token=credentials['SessionToken']
            )

        except Exception as e:
            print(e)
            pass
            continue

        try:
            print("\nScanning "+ region + " at account:" + acct)
            print("Instances: ",end='')
            response = ec2client.describe_instances()
            for reservation in response["Reservations"]:
                for instance in reservation['Instances']:
                    state = instance['State']['Name']
                    if state == 'running':
                        instanceId = instance['InstanceId']
                        groupid = instance['SecurityGroups'][0]['GroupId']
                        az = instance['Placement']['AvailabilityZone']
                        vpcId = instance['VpcId']
                        instanceType = instance['InstanceType']
                        rootDeviceType = instance['RootDeviceType']
                        eip = 'None'
                        if instance['NetworkInterfaces'] != None:
                            for nic in instance['NetworkInterfaces']:
                                if nic['Association'] != None:
                                    eip = nic['Association']['PublicIp']
                                else:
                                    eip = 'None'
                        else:
                            eip = 'NIC not present'
                        ebsOptimized = instance['EbsOptimized']
                        if 'Platform' in instance:
                            if instance['Platform'] == None:
                                platform = 'linux'
                            else:
                                platform = instance['Platform']
                        else:
                            platform = 'linux'

                        if 'IamInstanceProfile' in instance:
                            role = instance['IamInstanceProfile']['Arn']
                        else:
                            role = 'None'

                        writerinstance.writerow((acct, instanceId, instanceType, platform, region, az, vpcId,
                                         rootDeviceType, ebsOptimized, eip, role))
                        print(".", end="")

            print('\nRDS: ', end='')
            dbresponse = rdsclient.describe_db_instances()
            for dbinstance in dbresponse['DBInstances']:
                dbengine = dbinstance['Engine']
                dbinstancetype = dbinstance['DBInstanceClass']
                dbmultiaz = dbinstance['MultiAZ']
                dbstoragetype = dbinstance['StorageType']
                dbendpoint = dbinstance['Endpoint']['Address']
                dbaz = dbinstance['AvailabilityZone']
                
                writerrds.writerow((acct, dbengine, dbinstancetype, dbmultiaz, dbstoragetype, dbendpoint, dbaz))
                print(".", end="")

            print('\nEBS: ', end='')
            volumesJson = ec2client.describe_volumes()
            if volumesJson['Volumes'] != None:
                for vol in volumesJson['Volumes']:
                    az = vol['AvailabilityZone']
                    attinstanceid = vol['Attachments'][0]['InstanceId'] if vol['Attachments'] != None else 'detached'
                    volumeid = vol['Attachments'][0]['VolumeId'] if vol['Attachments'] != None else vol['volumeId']
                    attstate = vol['Attachments'][0]['State'] if vol['Attachments'] != None else 'detached'
                    encrypted = vol['Encrypted']
                    volumetype = vol['VolumeType']
                    state = vol['State']
                    size = vol['Size']

                    writerebs.writerow((acct, volumeid, az, attinstanceid, attstate, volumetype, size, state, encrypted))
                    print(".", end="")

        except Exception as e:
            print(e)
            pass


finstance.close()
frds.close()
febs.close()
print("\nEnd!")
