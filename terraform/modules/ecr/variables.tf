variable "project" {
  type    = string
  default = "dify"
}

variable "environment" {
  type = string
}

variable "tags" {
  type    = map(string)
  default = {}
}
