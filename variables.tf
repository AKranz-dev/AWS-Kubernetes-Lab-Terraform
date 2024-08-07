variable "awsRegion" {
  type    = string
  default = "us-east-1"
}

variable "instanceType" {
  type    = string
  default = "t2.medium"
}

variable "vpcID" {
  type    = string
  default = ""
}