resource "random_password" "db_password" {
  length  = 24
  special = false
}

resource "aws_ssm_parameter" "db_password" {
  name  = "/${var.project}/${var.environment}/db-password"
  type  = "SecureString"
  value = random_password.db_password.result
  tags  = var.tags
}

resource "aws_db_subnet_group" "main" {
  name       = "${var.project}-${var.environment}"
  subnet_ids = var.private_subnet_ids
  tags       = merge(var.tags, { Name = "${var.project}-${var.environment}-db-subnet" })
}

resource "aws_db_parameter_group" "main" {
  name_prefix = "${var.project}-${var.environment}-pg16-"
  family      = "postgres16"

  parameter {
    name         = "shared_preload_libraries"
    value        = "pg_stat_statements"
    apply_method = "pending-reboot"
  }

  tags = var.tags
  lifecycle { create_before_destroy = true }
}

resource "aws_db_instance" "main" {
  identifier     = "${var.project}-${var.environment}"
  engine         = "postgres"
  engine_version = "16"

  instance_class        = var.instance_class
  allocated_storage     = var.allocated_storage
  storage_type          = "gp3"
  multi_az              = var.multi_az
  db_name               = "dify"
  username              = "dify"
  password              = random_password.db_password.result
  parameter_group_name  = aws_db_parameter_group.main.name
  db_subnet_group_name  = aws_db_subnet_group.main.name
  vpc_security_group_ids = [var.security_group_id]

  skip_final_snapshot       = var.environment == "development"
  final_snapshot_identifier = var.environment == "development" ? null : "${var.project}-${var.environment}-final"
  backup_retention_period   = var.environment == "development" ? 1 : 7
  deletion_protection       = var.environment == "production"

  tags = merge(var.tags, { Name = "${var.project}-${var.environment}-rds" })
}
