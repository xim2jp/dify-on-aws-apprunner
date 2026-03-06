variable "project" {
  type    = string
  default = "dify"
}

variable "environment" {
  type = string
}

variable "account_id" {
  type = string
}

variable "versioning_enabled" {
  type    = bool
  default = false
}

variable "tags" {
  type    = map(string)
  default = {}
}
