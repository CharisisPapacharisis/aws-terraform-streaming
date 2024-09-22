import sys
from awsglue.transforms import *
from awsglue.utils import getResolvedOptions
from pyspark.context import SparkContext
from awsglue.context import GlueContext
from awsglue.job import Job
from awsglue.dynamicframe import DynamicFrame
import pyspark.sql.functions as functions
#sc = SparkContext()
sc = SparkContext.getOrCreate()
sys.argv+=['--JOB_NAME', 'stream-ETL-job']
args = getResolvedOptions(sys.argv, ['JOB_NAME','source_bucket','target_bucket', 'table_name'])
print(args)

glueContext = GlueContext(sc)
spark = glueContext.spark_session
job = Job(glueContext)
job.init(args['JOB_NAME'],args)
print(args)

table_name = args['table_name']
print('Table name is: ',table_name)

source_bucket = args['source_bucket']
print('Source bucket is: ',source_bucket)

target_bucket = args['target_bucket']
print('Target bucket is: ',target_bucket)

ETH_source_path = "s3://" + source_bucket + "/currency=ETH/"
print('eth source path is: ',ETH_source_path)
BTC_source_path = "s3://" + source_bucket + "/currency=BTC/"
print('btc source path is: ',BTC_source_path)
XRP_source_path = "s3://" + source_bucket + "/currency=XRP/"
print('xrp source path is: ',XRP_source_path)

target_path =  "s3://" + target_bucket + "/"
print('target path is: ',target_path)

# source dataset location
s3_source_bucket = [ETH_source_path, BTC_source_path, XRP_source_path]

# create aws glue dynamicframe using create_dynamic_frame_from_options by reading the source s3 location. With AWS Glue "job bookmark" feature enabled 
# the job will process incremental data since the last job run avoiding duplicate processing.
source_df = glueContext.create_dynamic_frame_from_options(
            connection_type="s3",
            connection_options = {
                "paths": s3_source_bucket,
                'recurse': True
            },
            format="json",
            transformation_ctx = "source_df")
source_df.printSchema()
source_df.show()
# convert aws glue dynamicframe to spark dataframe and show first rows of Spark dataframe
df1 = source_df.toDF()
df1.show(10)
# add new columns year, month, day, hour, which will be used for partitioning the data        
partitiondf = (df1
                .withColumn('year', functions.year(functions.col('timestamp_utc')))
                .withColumn('month', functions.month(functions.col('timestamp_utc')))
                .withColumn('day', functions.dayofmonth(functions.col('timestamp_utc')))
                .withColumn('hour', functions.hour(functions.col('timestamp_utc')))
            )
partitiondf.printSchema()
partitiondf.show(10)
#add date column and transform it to date format
partitiondf = partitiondf.withColumn('date',functions.to_date(functions.substring(functions.col('timestamp_utc'),1,10),'yyyy-MM-dd'))
partitiondf.show(10)
partitiondf.printSchema()
#convert string to timestamp and drop old column
partitiondf = partitiondf.withColumn('datetime', partitiondf.timestamp_utc.cast("timestamp"))
partitiondf = partitiondf.drop("timestamp_utc")
partitiondf.show(10)
#casting amount from string to float
partitiondf = partitiondf.withColumn('amount', partitiondf.amount.cast("float"))
partitiondf.printSchema()
partitiondf.show(10)
# convert spark dataframe to aws glue dynamicframe
gluedf = DynamicFrame.fromDF(
                partitiondf, glueContext, "gluedf")
 
# parameter "enableUpdateCatalog" tells the aws glue job to update the
# glue data catalog  as the new partitions are created
#additionalOptions = {"enableUpdateCatalog": True}
# destination dataset location
s3_destination_bucket = target_path
sink = glueContext.getSink(
    connection_type="s3", 
    path=s3_destination_bucket,
    enableUpdateCatalog=True,
    transformation_ctx = 'writing_parquet_to_s3',
    partitionKeys=["base", "year", "month", "day","hour"])
sink.setFormat("glueparquet")
sink.setCatalogInfo(catalogDatabase='currency_database', catalogTableName= table_name)
sink.writeFrame(gluedf)
# commit the glue job
job.commit()