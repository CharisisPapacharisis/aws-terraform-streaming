#common variables
variable "environment" {
  type = string
}

#kinesis variables

variable "kinesis_stream_retention_period" {
  type = number #default: 48
}
variable "kinesis_stream_mode" {
  type = string #default: ON_DEMAND
}
variable "kinesis_firehose_logging_retention_period" {
  type = number #default: 30
}

#api gateway variables
variable "stage_name" {
  type = string #default: dev
}
variable "quota_limit" {
  type = number #default: 100
}
variable "burst_limit" {
  type = number #default: 20
}
variable "rate_limit" {
  type = number #default: 20
}

#glue variables
variable "glue-arn" {
  type = string #"arn:aws:iam::XXXXXXXXXX:role/AWSGlueServiceRole-123"
}
variable "glue_job_timeout" {
  type = number # 2880
}
variable "glue_version" {
  type = string #"4.0"
}

#sns variables
variable "endpoint" {
  type = string
}

#lambda variables
variable "lambda_timeout" {
  type = number #30
}