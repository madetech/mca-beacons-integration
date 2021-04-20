resource "aws_secretsmanager_secret" "db_password" {
  name = "${var.env}_db_password"
}

resource "aws_secretsmanager_secret_version" "db_password" {
  secret_id     = aws_secretsmanager_secret.db_password.id
  secret_string = var.db_password
}

resource "aws_secretsmanager_secret" "gov_notify_api_key" {
  name = "${var.env}_gov_notify_api_key"
}

resource "aws_secretsmanager_secret_version" "gov_notify_api_key" {
  secret_id     = aws_secretsmanager_secret.gov_notify_api_key.id
  secret_string = var.gov_notify_api_key
}

resource "aws_secretsmanager_secret" "gov_notify_customer_email_template" {
  name = "${var.env}_gov_notify_customer_email_template"
}

resource "aws_secretsmanager_secret_version" "gov_notify_customer_email_template" {
  secret_id     = aws_secretsmanager_secret.gov_notify_customer_email_template.id
  secret_string = var.gov_notify_customer_email_template
}

resource "aws_secretsmanager_secret" "basic_auth" {
  name = "${var.env}_basic_auth"
}

resource "aws_secretsmanager_secret_version" "basic_auth" {
  secret_id     = aws_secretsmanager_secret.basic_auth.id
  secret_string = var.basic_auth
}