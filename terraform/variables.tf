variable "aws_region" {
  type    = string
  default = "ap-southeast-1"
}

variable "lambda_name" {
  type    = string
  default = "run-reflection-context"
}

variable "dynamodb_table_name" {
  type    = string
  default = "run-reflection-context"
}

variable "ttl_days" {
  type    = number
  default = 2
}

variable "morning_lambda_schedule" {
  type    = string
  default = "cron(0 21-23,0 ? * * *)" # 04:00, 05:00, 06:00, 07:00 Ho Chi Minh time
}

variable "latitude" {
  type    = number
  default = 10.77146093421298
}

variable "longitude" {
  type    = number
  default = 106.69823735664274
}
