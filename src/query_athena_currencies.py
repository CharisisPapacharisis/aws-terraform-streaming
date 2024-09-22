import time
import boto3
import datetime
import json
import os

target_table = os.environ["target_table"]

print ('Target table is: ',target_table)
# create Athena client
client = boto3.client('athena')

DATABASE = 'currency_database'
output='s3://my-name/athena-query-results/'

def lambda_handler(event, context):
    #diagnostics 
    print('event:', json.dumps(event))
    print('queryStringParameters:', json.dumps(event['queryStringParameters']))
    
    #get query string param inputs
    coin =  str(event['queryStringParameters']['coin'])
    start_date = datetime.datetime.strptime(event['queryStringParameters']['start_date'], "%Y-%m-%d").date()
    end_date = datetime.datetime.strptime(event['queryStringParameters']['end_date'], "%Y-%m-%d").date()
    print('start_date is: ',start_date)
    print('end_date is: ',end_date)
 
    query = 'with cte as (select max(amount) as max_amount from {} where base=\'{}\' and date>=date(\'{}\') and date<=date(\'{}\' )) \
             select datetime,amount from {} where amount in (select max_amount from cte)'.format(target_table, coin, start_date, end_date, target_table)
    
    # start execution
    response = client.start_query_execution(
        QueryString=query,
        QueryExecutionContext={
            'Database': DATABASE
        },
        ResultConfiguration={
            'OutputLocation': output,
        }
    )

    # get query execution id
    query_execution_id = response['QueryExecutionId']    
    
    #set state of status for the query, as soon as the query is triggered, before going into the WHILE loop
    state = 'QUEUED'
    
    while (state in ['RUNNING', 'QUEUED']):
   
        #get state of status for the query to see if it is succeeded  
        query_status = client.get_query_execution(QueryExecutionId=query_execution_id)
        print ('query_status is ',query_status)
        state = query_status['QueryExecution']['Status']['State']    
        print ('state is: ',state)
    time.sleep(1) #wait for one second between loops
    
    if state == 'SUCCEEDED':
        results = client.get_query_results(QueryExecutionId=query_execution_id)
        print('results: ',results)    
        
        for row in results['ResultSet']['Rows']:
            print(row)
        
        #prepare key values
        key1 = 'datetime'
        key2 = 'amount'
        value1 = results['ResultSet']['Rows'][1]['Data'][0]['VarCharValue']
        value2 = results['ResultSet']['Rows'][1]['Data'][1]['VarCharValue']
    else:
        print('killed')
        client.stop_query_execution(QueryExecutionId=query_execution_id)
    
    #prepare the response body
    res_body = {}
    res_body[key1] = value1
    res_body[key2] = value2

    #prepare http response
    http_res = {}
    http_res['statusCode'] = 200
    http_res['headers'] = {}
    http_res['headers']['Content-Type'] = 'application/json'
    http_res['body'] = json.dumps(res_body)
    
    return http_res
    
        
