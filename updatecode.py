from __future__ import print_function

import json
import urllib
import boto3
import logging

logger = logging.getLogger()
logger.setLevel(logging.INFO)

s3 = boto3.client('s3','us-east-1')
ssm = boto3.client('ssm','us-east-1')

def main_handler(event, context):
    record = event['Records'][0]
    isProd = False

    if 'Sns' in record:
        TopicArn = event['Records'][0]['Sns']['TopicArn']
        logger.info('Tiggered by SNS message {}'.format(TopicArn))
        # SNS is invoked only when autoscale spins up a new prod instance
        if '-prod' in TopicArn:
            isProd = True
    elif 'S3' in record:
        bucket = event['Records'][0]['s3']['bucket']['name']
        key = urllib.unquote_plus(event['Records'][0]['s3']['object']['key'].encode('utf8'))
        logger.info('Tiggered by S3 bucket {} key {}'.format(bucket, key))
        if '-prod' in key:
            isProd = True
    else:
        logger.error('Invalid Trigger')
        return {'result': False, 'msg': 'Invalid Trigger'}

    if isProd:
        TagKey = 'ws:autoscaling:groupName'
        TagName = 'web-asg-default'
        s3Key = 'app-prod'
    else:
        TagKey = 'stage'
        TagName = 'web-test'
        s3Key = 'app-test'

    try:
        response = ssm.send_command(
            Targets=[
                {
                    'Key': TagKey,
                    'Values': [
                        TagName
                    ]
                },
            ],
            DocumentName='Update-WebApp',
            DocumentHash='6fa7d85d49b33ea',
            DocumentHashType='Sha256',
            TimeoutSeconds=900,
            Comment='Update WebApp',
            Parameters={
                's3Key': [
                    s3Key,
                ]
            },
            OutputS3BucketName='bukcet',
            OutputS3KeyPrefix='deploylog',
            MaxConcurrency='2',
            MaxErrors='2',
            ServiceRoleArn='string',
            NotificationConfig={
                'NotificationArn': 'arn:aws:sns:us-east-1:0000000000:Web-Notifications',
                'NotificationEvents': [
                    'Success','TimedOut','Failed'
                ],
                'NotificationType': 'Invocation'
            }
        )

        logger.info(response)
        return {'result': True, 'msg': response}

    except ValueError, Argument:
        logger.error('Something went wrong {}',Argument)
        return {'result': False, 'msg': Argument}
