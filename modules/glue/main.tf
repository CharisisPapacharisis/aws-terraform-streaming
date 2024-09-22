
locals {
  object_source = "${path.module}/../../src/ETL_script.py"
}

#bucket for holding assets, basically code for glue job
resource "aws_s3_bucket" "bucket-abcd-001" {
  bucket = "${var.environment}-bucket-abcd-001"
}

resource "aws_s3_bucket_public_access_block" "bucket-abcd-001" {
  bucket = aws_s3_bucket.bucket-abcd-001.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

#bucket with bucket_logging for staging the data after the glue job
resource "aws_s3_bucket" "stream-data-staging-bucket" {
  bucket = "${var.environment}-stream-data-staging-bucket"
}

#read the bucket to be used for the logs
data "aws_s3_bucket" "my-name" {
  bucket = "my-name"
}

#creating logging of the "staging" s3 bucket, with target in the above bucket
resource "aws_s3_bucket_logging" "stream-logging" {
  bucket = aws_s3_bucket.stream-data-staging-bucket.id
  target_bucket = data.aws_s3_bucket.my-name.id
  target_prefix = "${var.environment}-staging-bucket-logs/"
}

resource "aws_s3_object" "upload_glue_script" {
  bucket = aws_s3_bucket.bucket-abcd-001.id
  key = "Scripts/stream-ETL-script.py" 
  source = local.object_source
  source_hash = filemd5(local.object_source)
}

resource "aws_glue_job" "stream-ETL-job" {
  name     = "${var.environment}-stream-ETL-job"
  role_arn = "${var.glue-arn}"
  timeout = var.glue_job_timeout

  command {
    script_location = "s3://${aws_s3_bucket.bucket-abcd-001.id}/Scripts/stream-ETL-script.py"
    python_version = 3
  }

  default_arguments = {    
    "--job-language"          = "python"
    "--ENV"                   = "env"
    "--enable-job-insights" = "false"
    "--job-bookmark-option"   = "job-bookmark-enable"
    "--TempDir"       = "s3://aws-glue-assets-XXXXXXXXXX-eu-west-1/temporary/"
    "--enable-glue-datacatalog"       = "true"
    "--library-set"       = "analytics"
    "--source_bucket"   = "${var.environment}-stream-data-landing-bucket"
    "--target_bucket"   = "${var.environment}-stream-data-staging-bucket"
    "--table_name"   = "${var.environment}_stream_data_staging_table"
  }

  depends_on = [
    aws_s3_object.upload_glue_script
  ]

  glue_version = var.glue_version
}