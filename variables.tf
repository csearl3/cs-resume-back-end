variable "region" {
  description = "AWS Region"
  type        = string
}

variable "dev_prefix" {
  type        = string
}

variable "rest_api_domain_name" {
  default     = "cs-resume.com"
  description = "Domain name of the API Gateway REST API for self-signed TLS certificate"
  type        = string
}