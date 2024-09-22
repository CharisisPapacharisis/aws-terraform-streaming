#common variables
environment = "dev"

#Kinesis variables
kinesis_stream_retention_period           = 48
kinesis_stream_mode                       = "ON_DEMAND"
kinesis_firehose_logging_retention_period = 30

#api gateway variables
stage_name  = "dev"
quota_limit = 100
burst_limit = 20
rate_limit  = 20

#glue variables
glue-arn         = "arn:aws:iam::XXXXXXXXXX:role/AWSGlueServiceRole-123"
glue_job_timeout = 2880
glue_version     = "4.0"

#sns variables
endpoint = "test@test.com"

#lambda variables
lambda_timeout = 30