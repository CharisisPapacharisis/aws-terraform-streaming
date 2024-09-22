resource "aws_iam_role" "coinbase_lambda_role" {
  name = "${var.environment}_coinbase_lambda_role"

  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
POLICY
}

resource "aws_iam_role_policy_attachment" "coinbase_lambda_basicexec_policy" {
  role       = aws_iam_role.coinbase_lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy_attachment" "coinbase_lambda_kinesis_policy" {
  role       = aws_iam_role.coinbase_lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonKinesisFullAccess"
}

resource "aws_iam_role_policy" "coinbase_lambda_secret_access_policy" {
  name = "${var.environment}_coinbase_lambda_secret_access_policy"
  role = aws_iam_role.coinbase_lambda_role.id

  # Terraform's "jsonencode" function converts a
  # Terraform expression result to valid JSON syntax.
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "secretsmanager:GetSecretValue",
        ]
        Effect   = "Allow"
        Resource = ["arn:aws:secretsmanager:eu-west-1:XXXXXXXXXX:secret:coin_api_key-Awzdhl"]
      },
    ]
  })
}

resource "aws_cloudwatch_log_group" "lambda_stream" {
  name = "/aws/lambda/${aws_lambda_function.coinbase_request.function_name}"

  retention_in_days = 14
}

############   addition from online reference
resource "null_resource" "install_python_dependencies" {
  provisioner "local-exec" {
    interpreter=["bash", "-c"]
    command = "pip3 install -r ${path.module}/../../src_coinbase_lambda/requirements.txt -t ${path.module}/../../src_coinbase_lambda/"

  }
  triggers = {
    #ts = timestamp()  #added this trigger to recreate the zip every time
    requirements = filesha1("${path.module}/../../src_coinbase_lambda/requirements.txt")
  }
}

data "archive_file" "lambda_coinbase" {
  depends_on = [null_resource.install_python_dependencies]
  source_dir = "${path.module}/../../src_coinbase_lambda/"
  output_path = "${path.module}/../../${var.environment}_lambda_coinbase.zip"
  type = "zip"
}

resource "aws_lambda_function" "coinbase_request" {
  function_name    = "${var.environment}_coinbase_request"
  handler          = "lambda_function.lambda_handler"
  runtime          = "python3.9"
  timeout          = 30
  filename         = data.archive_file.lambda_coinbase.output_path
  source_code_hash = data.archive_file.lambda_coinbase.output_base64sha256
  role             = aws_iam_role.coinbase_lambda_role.arn

  environment {
    variables = {
      kinesis_stream = "${var.environment}_kinesis_stream"  #this is the kinesis data stream where data will be written
    }
  }
}