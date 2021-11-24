variable "AWS_REGION" {
  description = "Deploy region"
}

variable "AWS_APP_NAME" {
  description = "Application name"
}

variable "AWS_APP_DOMAIN" {
  description = "Application name"
  default     = "nft.app.ixswap.io"
}

variable "AWS_APP_PARENT_ZONE" {
  description = "Application name"
  default     = "ixswap.io"
}

variable "AWS_ACM_ARN" {
  description = "AWS ACM public certificate identifier"
}

variable "ENVIRONMENT" {
  description = "Environment name"
}

variable "AWS_ACCOUNT_ID" {
  description = "AWS Account ID"
  default = "234891136725"
}

variable "AWS_CND_ERR_RESPONSE" {
  type = list
  description = "Custom error for 404 not found page, for fixing /auth response"
  default     = [{
    error_caching_min_ttl     = 10
    error_code                = 404
    response_code             = 200
    response_page_path        = "/images/"
  }]
}
