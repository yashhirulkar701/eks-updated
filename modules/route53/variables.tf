variable "route53_record" {
  type    = any
  default = {}
}

variable "zone_id" {
  type    = string
  default = ""
}

variable "env" {
  type    = string
  default = ""
}

variable "domain" {
  type    = string
  default = ""
}

variable "aws_region" {
  type    = string
  default = ""
}
