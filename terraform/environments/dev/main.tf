terraform {
  required_version = ">= 0.11.7"
}

data "aws_caller_identity" "current" {}

################################################################################
# Locals used for different Lambdas Environmental Variables
################################################################################

locals {

  redshift_loader_lambda_env_vars = {
    ENVIRONMENT = "${var.environment}"
    REGION      = "${var.aws_region}"
    IAM_ROLE    = "${var.redshift_data_loader_lambda_iam_role}"

    DB_HOST     = "${var.redshift_data_loader_lambda_db_host}"
    DB_PORT     = "${var.redshift_data_loader_lambda_db_port}"
    DB_NAME     = "${var.redshift_data_loader_lambda_db_name}"

    DB_USER     = "${var.redshift_data_loader_lambda_db_user}"
    DB_PW_PARAM = "${aws_ssm_parameter.redshift_lambda_db_password.name}"
    DB_SCHEMA   = "${var.redshift_data_loader_lambda_db_schema}"
    DB_TABLE    = "${var.redshift_data_loader_lambda_db_table}"
  }

  redshift_loader_lambda_dir = "${path.cwd}/../../../etl/lambda/redshift/"
}


################################################################################
# AWS Lambda IAM Policy document definitions
################################################################################

data "aws_iam_policy_document" "this" {
  statement {
    effect = "Allow"

    actions = [
      "s3:GetBucketLocation",
      "s3:ListAllMyBuckets",
    ]

    resources = [
      "*",
    ]
  }

  statement {
    effect = "Allow"

    actions = [
      "s3:Get*",
      "s3:List*",
      "s3:Describe*",
      "s3:RestoreObject",
    ]

    resources = [
      "*",
    ]
  }

  # Required if Lambda is created inside VPC
  statement {
    effect = "Allow"

    actions = [
      "ec2:DescribeNetworkInterfaces",
      "ec2:CreateNetworkInterface",
      "ec2:DeleteNetworkInterface",
    ]

    resources = [
      "*",
    ]
  }

  # Required if lambda requires specific Secrets from AWS SSM
  statement {
    effect = "Allow"

    actions = [
      "ssm:GetParameter",
    ]

    resources = [
      "${aws_ssm_parameter.redshift_lambda_db_password.arn}",
    ]
  }

  # Required if using encrypted data
  statement {
    effect = "Allow"

    actions = [
      "kms:ListKeys",
      "kms:Encrypt",
      "kms:Decrypt",
    ]

    resources = [
      "*",
    ]
  }

  statement {
    effect = "Allow"

    actions = [
      "sns:Publish",
    ]

    resources = [
      "${aws_sns_topic.lambda_sns_dql.arn}",
    ]
  }
}

################################################################################
# AWS Lambda function
################################################################################

module "redshift_loader_lambda" {

  source = "github.com/diogoaurelio/terraform-aws-lambda-module"
  version = "v0.0.1"

  aws_region     = "${var.aws_region}"
  aws_account_id = "${data.aws_caller_identity.current.account_id}"
  environment    = "${var.environment}"
  project        = "${var.project}"

  lambda_unique_function_name = "${var.redshift_loader_lambda_unique_function_name}"
  runtime                     = "${var.redshift_loader_lambda_runtime}"
  handler                     = "${var.redshift_loader_lambda_handler}"
  lambda_iam_role_name        = "${var.redshift_loader_lambda_role_name}"
  logs_kms_key_arn            = ""

  main_lambda_file  = "${var.redshift_loader_main_lambda_file}"
  lambda_source_dir = "${local.redshift_loader_lambda_dir}/src"

  lambda_zip_file_location = "${local.redshift_loader_lambda_dir}/${var.redshift_loader_main_lambda_file}.zip"
  lambda_env_vars          = "${local.redshift_loader_lambda_env_vars}"

  additional_policy = "${data.aws_iam_policy_document.this.json}"
  attach_policy     = true

  # configure Lambda function inside a specific VPC
  security_group_ids = ["${aws_security_group.this.id}"]
  subnet_ids         = "${split(",", var.private_subnet_ids)}"

  # DLQ
  use_dead_letter_config_target_arn = true
  dead_letter_config_target_arn     = "${aws_sns_topic.lambda_sns_dql.arn}"
}

################################################################################
# AWS Lambda Security Group
################################################################################

resource "aws_security_group" "this" {
  name        = "allow_all"
  description = "Allow all inbound traffic"
  vpc_id      = "${var.vpc_id}"

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
  }
}


################################################################################
# AWS trigger to invoke Lambda function on new S3 object
################################################################################

resource "aws_lambda_permission" "from_bucket" {
  statement_id  = "AllowExecutionFromS3Bucket"
  action        = "lambda:InvokeFunction"
  function_name = "${module.redshift_loader_lambda.aws_lambda_function_name}"
  principal     = "s3.amazonaws.com"
  source_arn    = "${var.s3_bucket_arn}"
}

resource "aws_s3_bucket_notification" "bucket_notification" {
  bucket = "${var.s3_bucket_name}"

  lambda_function {
    lambda_function_arn = "${module.redshift_loader_lambda.aws_lambda_function_arn}"
    events              = ["s3:ObjectCreated:*"]
    filter_prefix       = ""
    filter_suffix       = ""
  }

  depends_on = ["aws_lambda_permission.from_bucket"]
}

################################################################################
# Lambda KMS key used to encrypt Redshift secrets
################################################################################

resource "aws_kms_key" "redshift_secrets_key" {
  description             = "Used to encrypt secrets related to redshift cluster"
  is_enabled              = true
  key_usage               = "ENCRYPT_DECRYPT"
  deletion_window_in_days = "30"

  tags {
    Environment = "${var.environment}"
    Project     = "${var.project}"
    Name        = "redshift-secrets-key"
  }
}

################################################################################
# AWS SSM secret for Redshift user password
################################################################################

resource "aws_kms_alias" "redshift_secrets_key_alias" {
  name          = "alias/${var.environment}-${var.project}-redshift-secrets-key"
  target_key_id = "${aws_kms_key.redshift_secrets_key.arn}"
}

resource "aws_ssm_parameter" "redshift_lambda_db_password" {
  name        = "${var.environment}-${var.project}-redshift-lambda-password"
  description = "${var.environment} redshift lambda user password"
  type        = "SecureString"
  value       = "${var.redshift_data_loader_lambda_db_password}"
  key_id      = "${aws_kms_key.redshift_secrets_key.arn}"

  tags {
    Environment = "${var.environment}"
    Project     = "${var.project}"
    Name        = "redshift-lambda-password"
  }
}


################################################################################
# SNS topic for failure notifications
################################################################################

## SNS topic used for bucket triggered Redshift loading
resource "aws_sns_topic" "lambda_sns_dql" {
  name = "${var.environment}-${var.project}-${var.redshift_loader_lambda_unique_function_name}-dlq-sns-topic"
}
