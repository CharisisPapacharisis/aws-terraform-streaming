import boto3
import json
import os
from urllib.parse import unquote_plus

key_word = 'BTC'
topic_arn = os.environ["sns_arn_code"]

def send_sns(message, subject):
    try:
        client = boto3.client("sns")
        result = client.publish(TopicArn=topic_arn, Message=message, Subject=subject)
        if result['ResponseMetadata']['HTTPStatusCode'] == 200:
            print(result)
            print("Notification send successfully..!!!")
            return True
    except Exception as e:
        print("Error occured while publish notifications and error is : ", e)
        return False

def lambda_handler(event, context): 
   s3=boto3.client('s3')
   #the lambda is triggered when a new file lands into the bucket, that we will define as its trigger.
   my_bucket=event['Records'][0]['s3']['bucket']['name']
   print('bucket is: ', my_bucket)
   my_key_draft=str(event['Records'][0]['s3']['object']['key'])
   my_key = unquote_plus(my_key_draft)
   print('key is: ', my_key)

   if key_word in my_key:
      json_object = s3.get_object(Bucket=my_bucket, Key=my_key)
      print('object is: ',json_object)

      jsonFileReader = json_object['Body'].read()
      jsonDict = json.loads(jsonFileReader)
      print('data is: ', jsonDict)
      
      BTC_value = float(jsonDict['amount'])
      print('BTC_value is: ', BTC_value)
      ETH_value = float(jsonDict['amount'])
      XRP_value = float(jsonDict['amount'])
      
      if BTC_value >27500:
         message = "BTC value surpassed threshold, now trading at {} EUR".format(BTC_value)
         subject = "BTC price update"
         SNSResult = send_sns(message, subject)
         if SNSResult :
            print("Notification Sent..") 
            return SNSResult
         else:
            return False
   