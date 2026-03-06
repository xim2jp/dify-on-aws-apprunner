resource "random_password" "secret_key" {
  length  = 42
  special = false
}

resource "aws_ssm_parameter" "secret_key" {
  name  = "/${var.project}/${var.environment}/secret-key"
  type  = "SecureString"
  value = random_password.secret_key.result
  tags  = var.tags
}

# IAM role for App Runner to pull from ECR
resource "aws_iam_role" "access" {
  name = "${var.project}-${var.environment}-apprunner-access"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "build.apprunner.amazonaws.com"
      }
    }]
  })

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "ecr_access" {
  role       = aws_iam_role.access.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSAppRunnerServicePolicyForECRAccess"
}

# IAM instance role for the running service (S3, SSM access)
resource "aws_iam_role" "instance" {
  name = "${var.project}-${var.environment}-apprunner-instance"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "tasks.apprunner.amazonaws.com"
      }
    }]
  })

  tags = var.tags
}

resource "aws_iam_role_policy" "instance_s3" {
  name = "s3-access"
  role = aws_iam_role.instance.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "s3:GetObject",
        "s3:PutObject",
        "s3:DeleteObject",
        "s3:ListBucket"
      ]
      Resource = [
        var.s3_bucket_arn,
        "${var.s3_bucket_arn}/*"
      ]
    }]
  })
}

# VPC Connector
resource "aws_apprunner_vpc_connector" "main" {
  vpc_connector_name = "${var.project}-${var.environment}"
  subnets            = var.private_subnet_ids
  security_groups    = [var.apprunner_security_group_id]
  tags               = var.tags
}

# App Runner Service
resource "aws_apprunner_service" "main" {
  service_name = "${var.project}-${var.environment}"

  source_configuration {
    authentication_configuration {
      access_role_arn = aws_iam_role.access.arn
    }

    image_repository {
      image_identifier      = "${var.ecr_repository_url}:latest"
      image_repository_type = "ECR"

      image_configuration {
        port = "5001"

        runtime_environment_variables = {
          # Core
          MODE              = "api"
          SECRET_KEY        = random_password.secret_key.result
          CONSOLE_WEB_URL   = ""
          CONSOLE_API_URL   = ""
          SERVICE_API_URL   = ""
          APP_WEB_URL       = ""

          # Database
          DB_USERNAME = var.db_username
          DB_PASSWORD = var.db_password
          DB_HOST     = var.db_host
          DB_PORT     = tostring(var.db_port)
          DB_DATABASE = var.db_database

          # Redis
          REDIS_HOST     = var.redis_host
          REDIS_PORT     = "6379"
          REDIS_DB       = "0"
          REDIS_USE_SSL  = "false"

          # Celery Broker (use Redis instead of RabbitMQ)
          CELERY_BROKER_URL = "redis://${var.redis_host}:6379/1"
          BROKER_USE_SSL    = "false"

          # S3
          STORAGE_TYPE          = "s3"
          S3_BUCKET_NAME        = var.s3_bucket_name
          S3_REGION             = var.aws_region

          # Vector DB (pgvector)
          VECTOR_STORE = "pgvector"
          PGVECTOR_HOST     = var.db_host
          PGVECTOR_PORT     = tostring(var.db_port)
          PGVECTOR_USER     = var.db_username
          PGVECTOR_PASSWORD = var.db_password
          PGVECTOR_DATABASE = var.db_database

          # Plugin Daemon
          PLUGIN_API_URL              = "http://127.0.0.1:5002"
          PLUGIN_API_KEY              = random_password.secret_key.result
          PLUGIN_DAEMON_KEY           = random_password.secret_key.result
          INNER_API_KEY_FOR_PLUGIN    = random_password.secret_key.result
          PLUGIN_DIFY_INNER_API_KEY   = random_password.secret_key.result
          PLUGIN_DAEMON_URL           = "http://127.0.0.1:5002"
          MARKETPLACE_ENABLED         = "true"
          MARKETPLACE_API_URL         = "https://marketplace.dify.ai"
        }
      }
    }

    auto_deployments_enabled = false
  }

  instance_configuration {
    cpu               = var.cpu
    memory            = var.memory
    instance_role_arn = aws_iam_role.instance.arn
  }

  network_configuration {
    egress_configuration {
      egress_type       = "VPC"
      vpc_connector_arn = aws_apprunner_vpc_connector.main.arn
    }
  }

  health_check_configuration {
    protocol            = "HTTP"
    path                = "/health"
    interval            = 10
    timeout             = 5
    healthy_threshold   = 1
    unhealthy_threshold = 5
  }

  auto_scaling_configuration_arn = aws_apprunner_auto_scaling_configuration_version.main.arn

  tags = merge(var.tags, { Name = "${var.project}-${var.environment}-apprunner" })
}

resource "aws_apprunner_auto_scaling_configuration_version" "main" {
  auto_scaling_configuration_name = "${var.project}-${var.environment}"
  min_size                        = var.min_instances
  max_size                        = var.max_instances
  max_concurrency                 = 100
  tags                            = var.tags
}
