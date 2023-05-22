output "account_id" {
  value = local.account_id
}

output "dev_website_endpoint" {
  value = "http://${aws_s3_bucket_website_configuration.static.website_endpoint}"
}