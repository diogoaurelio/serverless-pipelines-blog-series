variable "aws_region" {
  description = "Default Region"
  default     = "eu-west-1"
}

variable "vpc_id" {
  description = "Existing VPC ID to use for apps deployment"
}

variable "environment" {
  description = "Environment of the Stack"
  default     = "dev"
}

variable "project" {
  description = "Specify to which project this resource belongs"
}

variable "s3_bucket_name" {
  description = "S3 Bucket name that triggers lambda function execution"
}

variable "s3_bucket_arn" {
  description = "S3 Bucket that triggers lambda function execution"
}

variable "private_subnet_ids" {
  description = "Comma-separated list of subnet ids"
}

################################################################################
# Lambda
################################################################################

variable "redshift_loader_lambda_role_name" {
  description = "Name of Role to be created exclusively for the lambda"
  default     = "data-loader-lambda-role"
}

variable "redshift_loader_main_lambda_file" {
  description = "Name of the main lambda .py file"
  default     = "lambda"
}

variable "redshift_loader_lambda_unique_function_name" {
  description = "Name of the lambda .py file"
  default     = "lambda-redshift-data-loader"
}

variable "redshift_loader_lambda_runtime" {
  description = "The languange/engine under which Lambda should run"
  default     = "python3.6"
}

variable "redshift_loader_lambda_handler" {
  description = "The name of the function handler inside the lambda main file"
  default     = "handler"
}

variable "redshift_data_loader_lambda_iam_role" {}

variable "redshift_data_loader_lambda_db_host" {}

variable "redshift_data_loader_lambda_db_name" {}

variable "redshift_data_loader_lambda_db_user" {}

variable "redshift_data_loader_lambda_db_password" {}

variable "redshift_data_loader_lambda_db_port" {
  default = "5439"
}

variable "redshift_data_loader_lambda_db_schema" {
  default = ""
}

variable "redshift_data_loader_lambda_db_table" {
  default = ""
}
