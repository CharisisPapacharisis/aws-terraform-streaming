terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.20"
    }
  }

  backend "s3" {
    bucket = "my-state-bucket"
    key    = "multi-environments/prod/terraform.tfstate"
    region = "eu-west-1"
    #shared_credentials_file = "/Users/user_name/.aws/credentials"
    #profile                  = "my_local_profile_name"
  }

  required_version = ">= 1.2.0"
}

provider "aws" {
  region = "eu-west-1"
  #shared_config_files      = ["/Users/user_name/.aws/config"]
  #shared_credentials_files = ["/Users/user_name/.aws/credentials"]
  #profile                  = "my_local_profile_name"
  default_tags {
    tags = {
      Owner   = "MyName"
      Project = "streaming_project"
    }
  }
}