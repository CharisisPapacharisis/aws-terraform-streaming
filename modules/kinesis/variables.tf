variable "environment" {
    type = string
}

variable "kinesis_stream_retention_period" {
    type = number          #default: 48
}

variable "kinesis_stream_mode" {
    type = string       #default: ON_DEMAND
}

variable "kinesis_firehose_logging_retention_period" {
    type = number       #default: 30
}