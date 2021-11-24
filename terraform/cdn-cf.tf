module "cdn" {
  source                        = "cloudposse/cloudfront-s3-cdn/aws"
  version                       = "0.45.1"
  name                          = "${var.AWS_APP_NAME}-${var.ENVIRONMENT}-s3-cdn"
  origin_bucket                 = "${var.AWS_APP_NAME}-${var.ENVIRONMENT}-s3"
  override_origin_bucket_policy = true
  aliases                       = ["${var.AWS_APP_DOMAIN}","www.${var.AWS_APP_DOMAIN}"]
  parent_zone_name              = var.AWS_APP_PARENT_ZONE
  dns_alias_enabled             = true
  acm_certificate_arn           = "${var.AWS_ACM_ARN}"
  use_regional_s3_endpoint      = true
  origin_force_destroy          = true
  versioning_enabled            = false
  logging_enabled               = true
  minimum_protocol_version      = "TLSv1"
  cors_allowed_headers          = ["*"]
  cors_allowed_methods          = ["GET", "HEAD", "PUT"]
  cors_allowed_origins          = ["${var.AWS_APP_DOMAIN}","*.diversi.fi"]
  cors_expose_headers           = ["ETag"]
  custom_error_response         = var.AWS_CND_ERR_RESPONSE
  tags = {
    Project     = var.AWS_APP_NAME
    Environment = var.ENVIRONMENT
    S3          = module.s3_bucket.bucket_id
  }
}
