module "s3_bucket" {
  source                                 = "cloudposse/s3-bucket/aws"
  version                                = "0.29.1"
  name                                   = "${var.AWS_APP_NAME}-${var.ENVIRONMENT}-s3"
  acl                                    = "private"
  enabled                                = true
  user_enabled                           = false
  force_destroy                          = true
  versioning_enabled                     = false
  block_public_acls                      = false
  abort_incomplete_multipart_upload_days = 2
  allowed_bucket_actions   = ["s3:GetObject", "s3:ListBucket", "s3:GetBucketLocation", "s3:PutObject", "s3:PutObjectAcl", "s3:DeleteObject", "s3:ListBucketMultipartUploads", "s3:AbortMultipartUpload", "s3:*"]
  grants = [
    {
      id          = "${var.AWS_ACCOUNT_ID}" # Canonical user or account id
      type        = "CanonicalUser"
      permissions = ["FULL_CONTROL"]
      uri         = null
    },
    {
      id          = null
      type        = "Group"
      permissions = ["FULL_CONTROL"]
      uri         = "http://acs.amazonaws.com/groups/global/AuthenticatedUsers"
    },
  ]
  tags = {
    Project     = var.AWS_APP_NAME
    Environment = var.ENVIRONMENT
    CDN         = "${var.AWS_APP_NAME}-${var.ENVIRONMENT}-s3-cdn"
  }
}