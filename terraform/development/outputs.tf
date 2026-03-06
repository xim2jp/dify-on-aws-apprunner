output "apprunner_url" {
  value = module.apprunner.service_url
}

output "rds_endpoint" {
  value = module.rds.endpoint
}

output "elasticache_endpoint" {
  value = module.elasticache.endpoint
}

output "s3_bucket_name" {
  value = module.s3.bucket_name
}

output "ecr_repository_url" {
  value = module.ecr.repository_url
}

output "vpc_id" {
  value = module.vpc.vpc_id
}

output "db_password_ssm_parameter" {
  value = module.rds.password_ssm_parameter
}
