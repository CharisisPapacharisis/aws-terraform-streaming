resource "aws_iam_role" "triggering_sns_lambda_role" {
  name   = "${var.environment}_trigger_sns_lambda_role"
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


resource "aws_iam_policy" "access_sns_queue" {
  name         = "${var.environment}_access_sns_queue"
  policy= jsonencode({
	"Version": "2012-10-17",
	"Statement": [
		{
			"Sid": "VisualEditor0",
			"Effect": "Allow",
			"Action": [
				"sns:PutDataProtectionPolicy",
				"sns:ListSubscriptionsByTopic",
				"sns:Publish",
				"sns:DeleteTopic",
				"sns:CreateTopic",
				"sns:Subscribe",
				"sns:ConfirmSubscription"
			],
			"Resource": "arn:aws:sns:eu-west-1:XXXXXXXXXX:${var.environment}_currency_notification_topic"
		},
		{
			"Sid": "VisualEditor1",
			"Effect": "Allow",
			"Action": [
				"sns:DeleteSMSSandboxPhoneNumber",
				"sns:ListSMSSandboxPhoneNumbers",
				"sns:CreatePlatformApplication",
				"sns:SetSMSAttributes",
				"sns:ListTopics",
				"sns:CreatePlatformEndpoint",
				"sns:Unsubscribe",
				"sns:ListSubscriptions",
				"sns:OptInPhoneNumber",
				"sns:ListOriginationNumbers",
				"sns:DeleteEndpoint",
				"sns:SetEndpointAttributes",
				"sns:ListEndpointsByPlatformApplication",
				"sns:SetSubscriptionAttributes",
				"sns:DeletePlatformApplication",
				"sns:CreateSMSSandboxPhoneNumber",
				"sns:SetPlatformApplicationAttributes",
				"sns:VerifySMSSandboxPhoneNumber",
				"sns:ListPlatformApplications"
			],
			"Resource": "*"
		}
	]
})
}


resource "aws_iam_policy" "access_landing_bucket" {
  name = "${var.environment}_access_landing_bucket"
  policy=jsonencode(
{
  	"Version": "2012-10-17",
	"Statement": [
		{
			"Sid": "VisualEditor0",
			"Effect": "Allow",
			"Action": [
				"s3:GetObjectVersionTagging",
				"s3:GetStorageLensConfigurationTagging",
				"s3:GetObjectAcl",
				"s3:GetBucketObjectLockConfiguration",
				"s3:GetIntelligentTieringConfiguration",
				"s3:GetObjectVersionAcl",
				"s3:GetBucketPolicyStatus",
				"s3:GetObjectRetention",
				"s3:GetBucketWebsite",
				"s3:GetJobTagging",
				"s3:GetMultiRegionAccessPoint",
				"s3:GetObjectAttributes",
				"s3:GetObjectLegalHold",
				"s3:GetBucketNotification",
				"s3:DescribeMultiRegionAccessPointOperation",
				"s3:GetReplicationConfiguration",
				"s3:ListMultipartUploadParts",
				"s3:GetObject",
				"s3:DescribeJob",
				"s3:GetAnalyticsConfiguration",
				"s3:GetObjectVersionForReplication",
				"s3:GetAccessPointForObjectLambda",
				"s3:GetStorageLensDashboard",
				"s3:GetLifecycleConfiguration",
				"s3:GetInventoryConfiguration",
				"s3:GetBucketTagging",
				"s3:GetAccessPointPolicyForObjectLambda",
				"s3:GetBucketLogging",
				"s3:ListBucketVersions",
				"s3:ListBucket",
				"s3:GetAccelerateConfiguration",
				"s3:GetObjectVersionAttributes",
				"s3:GetBucketPolicy",
				"s3:GetEncryptionConfiguration",
				"s3:GetObjectVersionTorrent",
				"s3:GetBucketRequestPayment",
				"s3:GetAccessPointPolicyStatus",
				"s3:GetObjectTagging",
				"s3:GetMetricsConfiguration",
				"s3:GetBucketOwnershipControls",
				"s3:GetBucketPublicAccessBlock",
				"s3:GetMultiRegionAccessPointPolicyStatus",
				"s3:ListBucketMultipartUploads",
				"s3:GetMultiRegionAccessPointPolicy",
				"s3:GetAccessPointPolicyStatusForObjectLambda",
				"s3:GetBucketVersioning",
				"s3:GetBucketAcl",
				"s3:GetAccessPointConfigurationForObjectLambda",
				"s3:GetObjectTorrent",
				"s3:GetMultiRegionAccessPointRoutes",
				"s3:GetStorageLensConfiguration",
				"s3:GetBucketCORS",
				"s3:GetBucketLocation",
				"s3:GetAccessPointPolicy",
				"s3:GetObjectVersion"
			],
			"Resource": [
				"arn:aws:s3:::${var.environment}-stream-data-landing",
				"arn:aws:s3:::${var.environment}-stream-data-landing/*"
			]
		},
		{
			"Sid": "VisualEditor1",
			"Effect": "Allow",
			"Action": [
				"s3:ListStorageLensConfigurations",
				"s3:ListAccessPointsForObjectLambda",
				"s3:GetAccessPoint",
				"s3:GetAccountPublicAccessBlock",
				"s3:ListAllMyBuckets",
				"s3:ListAccessPoints",
				"s3:ListJobs",
				"s3:ListMultiRegionAccessPoints"
			],
			"Resource": "*"
		}
	]
})
}


resource "aws_iam_policy" "triggering_sns_logs"{
  name = "${var.environment}_triggering_sns_logs"
  policy = jsonencode(
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
})
}


resource "aws_iam_role_policy_attachment" "access_sns_queue_attachment" {
  role       = aws_iam_role.triggering_sns_lambda_role.name
  policy_arn = aws_iam_policy.access_sns_queue.arn
}


resource "aws_iam_role_policy_attachment" "access_landing_bucket_attachment" {
  role       = aws_iam_role.triggering_sns_lambda_role.name
  policy_arn = aws_iam_policy.access_landing_bucket.arn
}

resource "aws_iam_role_policy_attachment" "triggering_sns_logs_attachment" {
  role       = aws_iam_role.triggering_sns_lambda_role.name
  policy_arn = aws_iam_policy.triggering_sns_logs.arn
}

data "archive_file" "zip_code" {
type        = "zip"
source_file  = "${path.module}/../../src/lambda_triggering_sns.py"
output_path = "${path.module}/../../src/${var.environment}_lambda_triggering_sns.zip"
}


# Adding S3 bucket as trigger to my lambda and giving the permissions
resource "aws_s3_bucket_notification" "s3-lambda-trigger" {
bucket = var.landing_bucket_id
lambda_function {
lambda_function_arn = aws_lambda_function.lambda_triggering_sns.arn
events              = ["s3:ObjectCreated:*"]
}
}


resource "aws_lambda_permission" "s3-lambda-permission" {
statement_id  = "AllowS3Invoke"
action        = "lambda:InvokeFunction"
function_name = aws_lambda_function.lambda_triggering_sns.function_name
principal = "s3.amazonaws.com"
source_arn = "arn:aws:s3:::${var.landing_bucket_id}"
}


resource "aws_lambda_function" "lambda_triggering_sns" {
  function_name    = "${var.environment}_lambda_triggering_sns"
  handler          = "lambda_triggering_sns.lambda_handler"
  runtime          = "python3.9"
  timeout          = var.lambda_timeout
  filename         = data.archive_file.zip_code.output_path
  source_code_hash = data.archive_file.zip_code.output_base64sha256
  role             = aws_iam_role.triggering_sns_lambda_role.arn
  depends_on       = [aws_iam_role_policy_attachment.access_sns_queue_attachment, aws_iam_role_policy_attachment.triggering_sns_logs_attachment, aws_iam_role_policy_attachment.access_landing_bucket_attachment]

  environment {
    variables = {
	  sns_arn_code = var.topic_arn # Arn from the defined sns resource.
    }
  }
}