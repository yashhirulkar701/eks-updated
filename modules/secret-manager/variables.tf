variable "secret_manager_name" {
  type    = string
  default = ""
}

variable "secret_manager_kms_key_arn" {
  type    = string
  default = ""
}

variable "tags" {
  type    = map(string)
  default = {}
}
