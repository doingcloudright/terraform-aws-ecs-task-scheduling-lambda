variable "create" {
  type    = bool
  default = true
}

variable "name" {
  type = string
}

variable "tags" {
  type    = map
  default = {}
}

variable "lambda_runtime" {
  type    = string
  default = "nodejs12.x"
}
