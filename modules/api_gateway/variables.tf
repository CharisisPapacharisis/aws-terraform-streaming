variable "environment" {
    type = string
}

variable "stage_name" {
    type = string   #default: dev
}

variable "quota_limit" {
    type = number  #default: 100
}

variable "burst_limit" {
    type = number  #default: 20
}

variable "rate_limit" {
    type = number  #default: 20
}

variable "function_name" {
    type = string   # inherited from another module
}

variable "integration_uri" {
    type = string   # inherited from another module
}