module "kinesis" {
  source = "../../modules/kinesis"

  environment                               = var.environment
  kinesis_stream_retention_period           = var.kinesis_stream_retention_period
  kinesis_stream_mode                       = var.kinesis_stream_mode
  kinesis_firehose_logging_retention_period = var.kinesis_firehose_logging_retention_period
}


module "api_gateway" {
  source = "../../modules/api_gateway"

  environment     = var.environment
  stage_name      = var.stage_name
  quota_limit     = var.quota_limit
  burst_limit     = var.burst_limit
  rate_limit      = var.rate_limit
  function_name   = module.lambda_query_athena.query_athena_lambda_name
  integration_uri = module.lambda_query_athena.integration_uri
}


module "glue" {
  source = "../../modules/glue"

  environment      = var.environment
  glue-arn         = var.glue-arn
  glue_job_timeout = var.glue_job_timeout
  glue_version     = var.glue_version
}

module "sns" {
  source = "../../modules/sns"

  environment = var.environment
  endpoint    = var.endpoint
}

module "lambda_trigger_sns" {
  source = "../../modules/lambda_trigger_sns"

  environment       = var.environment
  lambda_timeout    = var.lambda_timeout
  topic_arn         = module.sns.topic_arn
  landing_bucket_id = module.kinesis.landing_bucket_id
}

module "lambda_query_athena" {
  source = "../../modules/lambda_query_athena"

  environment    = var.environment
  lambda_timeout = var.lambda_timeout
}

module "lambda_coinbase" {
  source = "../../modules/lambda_coinbase"

  environment = var.environment
}