import boto3
from botocore.exceptions import ClientError
import json

def get_secret(key):

    secret_name = key
    region_name = "eu-west-1"

    # Create a Secrets Manager client
    session = boto3.session.Session()
    client = session.client(
        service_name='secretsmanager',
        region_name=region_name
    )

    try:
        get_secret_value_response = client.get_secret_value(
            SecretId=secret_name
        )
    except ClientError as e:
        raise e

    # Decrypts secret using the associated KMS key.
    api_secrets = get_secret_value_response['SecretString']
    #convert  the string-ified dictionary, to actual dictionary
    api_secrets_dict = json.loads(api_secrets)
    #extract dictionary values, based on dictionary keys
    api_key = api_secrets_dict['api_key']
    api_secret = api_secrets_dict['api_secret']

    return api_key,api_secret