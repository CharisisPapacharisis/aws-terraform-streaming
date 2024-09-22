
resource "aws_iam_role" "query_athena_lambda_role" {
  name   = "${var.environment}_query_athena_lambda_role"
  assume_role_policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
    {
        "Action": "sts:AssumeRole",
        "Principal": {
        "Service": "lambda.amazonaws.com"
        },
        "Effect": "Allow",
        "Sid": ""
    }
    ]
}
EOF
}

data "aws_iam_policy" "AmazonAthenaFullAccess" {
  arn = "arn:aws:iam::aws:policy/AmazonAthenaFullAccess"
}
resource "aws_iam_role_policy_attachment" "AthenaFullAccess_attachment" {
  role       = aws_iam_role.query_athena_lambda_role.name
  policy_arn = data.aws_iam_policy.AmazonAthenaFullAccess.arn
}


data "aws_iam_policy" "AWSGlueConsoleFullAccess" {
  arn = "arn:aws:iam::aws:policy/AWSGlueConsoleFullAccess"
}
resource "aws_iam_role_policy_attachment" "GlueConsoleFullAccess_attachment" {
  role       = aws_iam_role.query_athena_lambda_role.name
  policy_arn = data.aws_iam_policy.AWSGlueConsoleFullAccess.arn
}

resource "aws_iam_policy" "query_athena_lambda_logs"{
  name = "${var.environment}_query_athena_lambda_logs"
  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": "logs:CreateLogGroup",
            "Resource": "arn:aws:logs:*:*:*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "logs:CreateLogStream",
                "logs:PutLogEvents"
            ],
            "Resource": "arn:aws:logs:*:*:*"
        }
    ]
}
EOF
}
resource "aws_iam_role_policy_attachment" "QueryLogs_attachment" {
  role       = aws_iam_role.query_athena_lambda_role.name
  policy_arn = aws_iam_policy.query_athena_lambda_logs.arn
}

resource "aws_iam_policy" "full_access_staging_bucket"{
  name = "${var.environment}_full_access_staging_bucket"
  policy = jsonencode(
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "VisualEditor0",
            "Effect": "Allow",
            "Action": [
                "s3:ListStorageLensConfigurations",
                "s3:ListAccessPointsForObjectLambda",
                "s3:GetAccessPoint",
                "s3:PutAccountPublicAccessBlock",
                "s3:GetAccountPublicAccessBlock",
                "s3:ListAllMyBuckets",
                "s3:ListAccessPoints",
                "s3:PutAccessPointPublicAccessBlock",
                "s3:ListJobs",
                "s3:PutStorageLensConfiguration",
                "s3:ListMultiRegionAccessPoints",
                "s3:CreateJob"
            ],
            "Resource": "*"
        },
        {
            "Sid": "VisualEditor1",
            "Effect": "Allow",
            "Action": "s3:*",
            "Resource": [
                "arn:aws:s3:::${var.environment}-stream-data-staging",
                "arn:aws:s3:::${var.environment}-stream-data-staging/*"
            ]
        }
    ]
})
}
resource "aws_iam_role_policy_attachment" "StagingBucketAccess_attachment" {
  role       = aws_iam_role.query_athena_lambda_role.name
  policy_arn = aws_iam_policy.full_access_staging_bucket.arn
}

resource "aws_iam_policy" "bucket_access_output_queries"{
  name = "${var.environment}_bucket_access_output_queries"
  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "VisualEditor0",
            "Effect": "Allow",
            "Action": [
                "s3:ListStorageLensConfigurations",
                "s3:ListAccessPointsForObjectLambda",
                "s3:GetAccessPoint",
                "s3:PutAccountPublicAccessBlock",
                "s3:GetAccountPublicAccessBlock",
                "s3:ListAllMyBuckets",
                "s3:ListAccessPoints",
                "s3:PutAccessPointPublicAccessBlock",
                "s3:ListJobs",
                "s3:PutStorageLensConfiguration",
                "s3:ListMultiRegionAccessPoints",
                "s3:CreateJob"
            ],
            "Resource": "*"
        },
        {
            "Sid": "VisualEditor1",
            "Effect": "Allow",
            "Action": "s3:*",
            "Resource": [
                "arn:aws:s3:::my-name/athena-query-results",
                "arn:aws:s3:::my-name/athena-query-results/*"
            ]
        }
    ]
}
EOF
}
resource "aws_iam_role_policy_attachment" "BucketQutputQueries_attachment" {
  role       = aws_iam_role.query_athena_lambda_role.name
  policy_arn = aws_iam_policy.bucket_access_output_queries.arn
}

data "archive_file" "query_athena_code" {
type        = "zip"
source_file  = "${path.module}/../../src/query_athena_currencies.py"
output_path = "${path.module}/../../src/query_athena_code.zip"
}

resource "aws_lambda_function" "query-athena-currencies" {
  function_name    = "${var.environment}_query-athena-currencies"
  handler          = "query_athena_currencies.lambda_handler"
  runtime          = "python3.9"
  timeout          = var.lambda_timeout
  filename         = data.archive_file.query_athena_code.output_path
  source_code_hash = data.archive_file.query_athena_code.output_base64sha256
  role             = aws_iam_role.query_athena_lambda_role.arn
  depends_on       = [aws_iam_role_policy_attachment.BucketQutputQueries_attachment,aws_iam_role_policy_attachment.StagingBucketAccess_attachment,aws_iam_role_policy_attachment.QueryLogs_attachment,
                        aws_iam_role_policy_attachment.AthenaFullAccess_attachment, aws_iam_role_policy_attachment.GlueConsoleFullAccess_attachment]

  environment {
    variables = {
      target_table = "${var.environment}_stream_data_staging"  #table in data catalog
    }
  }
}