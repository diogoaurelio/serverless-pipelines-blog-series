################################################################################
# General Output
################################################################################

output "account_id" {
  value = "${data.aws_caller_identity.current.account_id}"
}

output "caller_arn" {
  value = "${data.aws_caller_identity.current.arn}"
}

output "caller_user" {
  value = "${data.aws_caller_identity.current.user_id}"
}

## SSM paramter name
output "aws_ssm_parameter_redshift_lambda_db_password_name" {
  value = "${aws_ssm_parameter.redshift_lambda_db_password.name}"
}
