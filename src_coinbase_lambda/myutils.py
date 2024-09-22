import boto3
import uuid
import json

def write_to_kinesis_data_stream(event, KinesisStream):

    kinesis_client = boto3.client('kinesis')

    resp = kinesis_client.put_record(
        StreamName = KinesisStream, #use the parameter as passed from terraform to the coinbase lambda function
        Data = event,
        PartitionKey = str(uuid.uuid4()))
    return resp