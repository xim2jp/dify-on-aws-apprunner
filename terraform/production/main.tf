locals {
  tags = {
    Project     = var.project
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}

module "vpc" {
  source            = "../modules/vpc"
  project           = var.project
  environment       = var.environment
  vpc_cidr          = var.vpc_cidr
  nat_gateway_count = var.nat_gateway_count
  tags              = local.tags
}

module "rds" {
  source             = "../modules/rds"
  project            = var.project
  environment        = var.environment
  private_subnet_ids = module.vpc.private_subnet_ids
  security_group_id  = module.vpc.database_security_group_id
  instance_class     = var.rds_instance_class
  allocated_storage  = var.rds_allocated_storage
  multi_az           = var.rds_multi_az
  tags               = local.tags
}

module "elasticache" {
  source             = "../modules/elasticache"
  project            = var.project
  environment        = var.environment
  private_subnet_ids = module.vpc.private_subnet_ids
  security_group_id  = module.vpc.database_security_group_id
  node_type          = var.redis_node_type
  num_cache_clusters = var.redis_num_cache_clusters
  tags               = local.tags
}

module "s3" {
  source             = "../modules/s3"
  project            = var.project
  environment        = var.environment
  account_id         = var.aws_account_id
  versioning_enabled = var.s3_versioning
  tags               = local.tags
}

module "ecr" {
  source      = "../modules/ecr"
  project     = var.project
  environment = var.environment
  tags        = local.tags
}

module "apprunner" {
  source                      = "../modules/apprunner"
  project                     = var.project
  environment                 = var.environment
  aws_region                  = var.aws_region
  ecr_repository_url          = module.ecr.repository_url
  private_subnet_ids          = module.vpc.private_subnet_ids
  apprunner_security_group_id = module.vpc.apprunner_security_group_id
  s3_bucket_name              = module.s3.bucket_name
  s3_bucket_arn               = module.s3.bucket_arn
  db_host                     = module.rds.host
  db_port                     = module.rds.port
  db_database                 = module.rds.database_name
  db_username                 = module.rds.username
  db_password                 = module.rds.password
  redis_host                  = module.elasticache.endpoint
  cpu                         = var.apprunner_cpu
  memory                      = var.apprunner_memory
  min_instances               = var.apprunner_min_instances
  max_instances               = var.apprunner_max_instances
  tags                        = local.tags
}
