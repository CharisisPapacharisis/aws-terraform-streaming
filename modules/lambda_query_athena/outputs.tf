output "query_athena_lambda_name" {
    value = aws_lambda_function.query-athena-currencies.function_name
}

output "integration_uri" {
    value = aws_lambda_function.query-athena-currencies.invoke_arn
}