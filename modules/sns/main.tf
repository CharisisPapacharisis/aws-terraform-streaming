resource "aws_sns_topic" "currency_notification_topic" {
  name = "${var.environment}_currency_notification_topic"
}

#subscription that subscribes to topic, where lambda is pushing the message. The endpoint of the subscription is the user's email.
resource "aws_sns_topic_subscription" "send_email" {
  topic_arn =  aws_sns_topic.currency_notification_topic.arn
  protocol  = "email"
  endpoint  = var.endpoint
}