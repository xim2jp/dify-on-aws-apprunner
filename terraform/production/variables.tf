variable "project" {
  type    = string
  default = "dify"
}

variable "environment" {
  type    = string
  default = "development"
}

variable "aws_region" {
  type    = string
  default = "ap-northeast-1"
}

variable "aws_account_id" {
  type    = string
  default = "337257207190"
}

variable "vpc_cidr" {
  type    = string
  default = "10.0.0.0/16"
}

variable "nat_gateway_count" {
  type    = number
  default = 1
}

variable "rds_instance_class" {
  type    = string
  default = "db.t4g.micro"
}

variable "rds_allocated_storage" {
  type    = number
  default = 20
}

variable "rds_multi_az" {
  type    = bool
  default = false
}

variable "redis_node_type" {
  type    = string
  default = "cache.t4g.micro"
}

variable "redis_num_cache_clusters" {
  type    = number
  default = 1
}

variable "s3_versioning" {
  type    = bool
  default = false
}

variable "apprunner_cpu" {
  type    = string
  default = "1024"
}

variable "apprunner_memory" {
  type    = string
  default = "2048"
}

variable "apprunner_min_instances" {
  type    = number
  default = 1
}

variable "apprunner_max_instances" {
  type    = number
  default = 2
}
