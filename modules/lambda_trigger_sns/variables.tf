variable "environment" {
    type = string
}

variable "lambda_timeout" {
    type = number   #30
}

variable "topic_arn" {
    type = string   
}

variable "landing_bucket_id"{
    type = string   
}