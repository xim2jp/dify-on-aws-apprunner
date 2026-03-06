variable "project" {
  type    = string
  default = "dify"
}

variable "environment" {
  type = string
}

variable "vpc_cidr" {
  type    = string
  default = "10.0.0.0/16"
}

variable "nat_gateway_count" {
  type    = number
  default = 1
}

variable "tags" {
  type    = map(string)
  default = {}
}
