resource "aws_kinesis_stream" "kinesis_stream" {
  name             = "${var.environment}_kinesis_stream"
  retention_period = var.kinesis_stream_retention_period

  shard_level_metrics = [
    "IncomingBytes",
    "OutgoingBytes",
  ]

  stream_mode_details {
    stream_mode = var.kinesis_stream_mode
  }
}

resource "aws_s3_bucket" "stream-data-landing-bucket" {
  bucket = "${var.environment}-stream-data-landing-bucket"
}

#cloudwatch details for firehose
resource "aws_cloudwatch_log_group" "firehose_stream_logging_group" {
  name = "/aws/kinesisfirehose/${var.environment}_firehose_stream_logging_group"
  retention_in_days = var.kinesis_firehose_logging_retention_period
}

resource "aws_cloudwatch_log_stream" "firehose_stream_logging_stream" {
  log_group_name = aws_cloudwatch_log_group.firehose_stream_logging_group.name
  name           = "${var.environment}_record_delivery"
}

resource "aws_iam_role" "stream_firehose_role" {
  name               = "${var.environment}_stream_firehose_role"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "firehose.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "stream_firehose_policy" {
  name = "${var.environment}_stream_firehose_policy"
  role = aws_iam_role.stream_firehose_role.id

  # Terraform's "jsonencode" function converts a 
  # Terraform expression result to valid JSON syntax. And allows for use of variables in it!
  policy = jsonencode({
    Version = "2012-10-17"
    "Statement": [
        {
            "Sid": "",
            "Effect": "Allow",
            "Action": [
                "glue:GetTable",
                "glue:GetTableVersion",
                "glue:GetTableVersions"
            ],
            "Resource": [
                "arn:aws:glue:eu-west-1:XXXXXXXXXX:catalog",
                "arn:aws:glue:eu-west-1:XXXXXXXXXX:database/%FIREHOSE_POLICY_TEMPLATE_PLACEHOLDER%",
                "arn:aws:glue:eu-west-1:XXXXXXXXXX:table/%FIREHOSE_POLICY_TEMPLATE_PLACEHOLDER%/%FIREHOSE_POLICY_TEMPLATE_PLACEHOLDER%"
            ]
        },
        {
            "Sid": "",
            "Effect": "Allow",
            "Action": [
                "kafka:GetBootstrapBrokers",
                "kafka:DescribeCluster",
                "kafka:DescribeClusterV2",
                "kafka-cluster:Connect"
            ],
            "Resource": "arn:aws:kafka:eu-west-1:XXXXXXXXXX:cluster/%FIREHOSE_POLICY_TEMPLATE_PLACEHOLDER%/%FIREHOSE_POLICY_TEMPLATE_PLACEHOLDER%"
        },
        {
            "Sid": "",
            "Effect": "Allow",
            "Action": [
                "kafka-cluster:DescribeTopic",
                "kafka-cluster:DescribeTopicDynamicConfiguration",
                "kafka-cluster:ReadData"
            ],
            "Resource": "arn:aws:kafka:eu-west-1:XXXXXXXXXX:topic/%FIREHOSE_POLICY_TEMPLATE_PLACEHOLDER%/%FIREHOSE_POLICY_TEMPLATE_PLACEHOLDER%/%FIREHOSE_POLICY_TEMPLATE_PLACEHOLDER%"
        },
        {
            "Sid": "",
            "Effect": "Allow",
            "Action": [
                "kafka-cluster:DescribeGroup"
            ],
            "Resource": "arn:aws:kafka:eu-west-1:XXXXXXXXXX:group/%FIREHOSE_POLICY_TEMPLATE_PLACEHOLDER%/%FIREHOSE_POLICY_TEMPLATE_PLACEHOLDER%/*"
        },
        {
            "Sid": "",
            "Effect": "Allow",
            "Action": [
                "s3:AbortMultipartUpload",
                "s3:GetBucketLocation",
                "s3:GetObject",
                "s3:ListBucket",
                "s3:ListBucketMultipartUploads",
                "s3:PutObject"
            ],
            "Resource": [
                "arn:aws:s3:::${var.environment}-stream-data-landing-bucket",
                "arn:aws:s3:::${var.environment}-stream-data-landing-bucket/*"
            ]
        },
        {
            "Sid": "",
            "Effect": "Allow",
            "Action": [
                "lambda:InvokeFunction",
                "lambda:GetFunctionConfiguration"
            ],
            "Resource": "arn:aws:lambda:eu-west-1:XXXXXXXXXX:function:%FIREHOSE_POLICY_TEMPLATE_PLACEHOLDER%"
        },
        {
            "Effect": "Allow",
            "Action": [
                "kms:GenerateDataKey",
                "kms:Decrypt"
            ],
            "Resource": [
                "arn:aws:kms:eu-west-1:XXXXXXXXXX:key/%FIREHOSE_POLICY_TEMPLATE_PLACEHOLDER%"
            ],
            "Condition": {
                "StringEquals": {
                    "kms:ViaService": "s3.eu-west-1.amazonaws.com"
                },
                "StringLike": {
                    "kms:EncryptionContext:aws:s3:arn": [
                        "arn:aws:s3:::%FIREHOSE_POLICY_TEMPLATE_PLACEHOLDER%/*",
                        "arn:aws:s3:::%FIREHOSE_POLICY_TEMPLATE_PLACEHOLDER%"
                    ]
                }
            }
        },
        {
            "Sid": "",
            "Effect": "Allow",
            "Action": [
                "logs:PutLogEvents"
            ],
            "Resource": [
                "arn:aws:logs:eu-west-1:XXXXXXXXXX:log-group:/aws/kinesisfirehose/${var.environment}_firehose_stream_logging_group:log-stream:*",
                "arn:aws:logs:eu-west-1:XXXXXXXXXX:log-group:%FIREHOSE_POLICY_TEMPLATE_PLACEHOLDER%:log-stream:*"
            ]
        },
        {
            "Sid": "",
            "Effect": "Allow",
            "Action": [
                "kinesis:DescribeStream",
                "kinesis:GetShardIterator",
                "kinesis:GetRecords",
                "kinesis:ListShards"
            ],
            "Resource": "arn:aws:kinesis:eu-west-1:XXXXXXXXXX:stream/${var.environment}_kinesis_stream"
        },
        {
            "Effect": "Allow",
            "Action": [
                "kms:Decrypt"
            ],
            "Resource": [
                "arn:aws:kms:eu-west-1:XXXXXXXXXX:key/%FIREHOSE_POLICY_TEMPLATE_PLACEHOLDER%"
            ],
            "Condition": {
                "StringEquals": {
                    "kms:ViaService": "kinesis.eu-west-1.amazonaws.com"
                },
                "StringLike": {
                    "kms:EncryptionContext:aws:kinesis:arn": "arn:aws:kinesis:eu-west-1:XXXXXXXXXX:stream/${var.environment}_kinesis_stream"
                }
            }
        }
    ]
  })
}


resource "aws_kinesis_firehose_delivery_stream" "stream_firehose" {
  name        = "${var.environment}_stream_firehose"
  destination = "extended_s3"

  kinesis_source_configuration {
    kinesis_stream_arn = aws_kinesis_stream.kinesis_stream.arn
    role_arn           = aws_iam_role.stream_firehose_role.arn
  }
  extended_s3_configuration {
    bucket_arn = aws_s3_bucket.stream-data-landing-bucket.arn
    role_arn   = aws_iam_role.stream_firehose_role.arn
    #buffer_size = 128

    cloudwatch_logging_options {
      enabled = true
      log_group_name  = aws_cloudwatch_log_group.firehose_stream_logging_group.name
      log_stream_name = aws_cloudwatch_log_stream.firehose_stream_logging_stream.name
    }
    
    # https://docs.aws.amazon.com/firehose/latest/dev/dynamic-partitioning.html
    dynamic_partitioning_configuration {
      enabled = "true"
    }
    # Example prefix using partitionKeyFromQuery, applicable to JQ processor
    prefix              = "currency=!{partitionKeyFromQuery:currency}/year=!{partitionKeyFromQuery:year}/month=!{partitionKeyFromQuery:month}/day=!{partitionKeyFromQuery:day}/"
    error_output_prefix = "errors/year=!{timestamp:yyyy}/month=!{timestamp:MM}/day=!{timestamp:dd}/hour=!{timestamp:HH}/!{firehose:error-output-type}/"

    processing_configuration {
      enabled = "true"

      # Multi-record deaggregation processor example
      processors {
        type = "RecordDeAggregation"
        parameters {
          parameter_name  = "SubRecordType"
          parameter_value = "JSON"
        }
      }

      #metadata extraction
      processors {
        type = "MetadataExtraction"
        parameters {
          parameter_name  = "JsonParsingEngine"
          parameter_value = "JQ-1.6"
        }
        parameters {
          parameter_name  = "MetadataExtractionQuery"
          parameter_value = "{currency:.base,year:.timestamp_utc|strptime(\"%Y-%m-%dT%H:%M:%SZ\")|strftime(\"%Y\"),month:.timestamp_utc|strptime(\"%Y-%m-%dT%H:%M:%SZ\")|strftime(\"%m\"),day:.timestamp_utc|strptime(\"%Y-%m-%dT%H:%M:%SZ\")|strftime(\"%d\")}"
        }
      }
    }
  }
}