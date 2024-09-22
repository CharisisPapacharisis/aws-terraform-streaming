variable "glue-arn"  {
  type = string #default = "arn:aws:iam::XXXXXXXXXX:role/AWSGlueServiceRole-123"
}

variable "environment" {
    type = string
}

variable "glue_version" {
  type = string   #"4.0"
}

variable "glue_job_timeout" {
  type = number # 2880
}