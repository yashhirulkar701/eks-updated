variable "ecr_repository_name" {
  type    = string
  default = ""
}

variable "tags" {
  type    = map(string)
  default = {}
}
