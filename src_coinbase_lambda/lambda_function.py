import json
import coinbase  
from coinbase.wallet.client import Client
from datetime import datetime
from myutils import write_to_kinesis_data_stream
from secret_read import get_secret 
import os

kinesis_stream = os.environ["kinesis_stream"]

def lambda_handler(event, context):

    api_key,api_secret = get_secret('coin_api_key')
    api_client = Client(api_key, api_secret)

    coins = ['BTC','ETH','XRP']

    utc_time = datetime.utcnow()
    utc_time_str = utc_time.strftime("%Y-%m-%dT%H:%M:%SZ") 

    for coin in coins: 
        argument = coin+'-USD'
        print ('argument: ',argument)
        data = api_client.get_spot_price(currency_pair = argument)

        #add date detail to json object: 
        data['timestamp_utc'] = utc_time_str
        print ('data: ', data)

        #convert to string
        data_string = str(data)

        #convert to bytes
        data_as_bytes = bytes(data_string, encoding='utf8')

        #send data inside the loop, for all three api calls
        response = write_to_kinesis_data_stream(data_as_bytes, KinesisStream=kinesis_stream)
        print('response of sending to kinesis :', response)