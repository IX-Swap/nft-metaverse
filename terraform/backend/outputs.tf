output "state_bucket" {
  description = "ARN of the S3 bucket the state is stored"
  value       = module.terraform_state_backend.s3_bucket_arn
}

output "bucket_id" {
  description = "ID/Name of the app S3 bucket"
  value       = module.s3_bucket.bucket_id
}
