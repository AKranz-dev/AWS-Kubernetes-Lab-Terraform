variable "awsRegion" {
  type    = string
  default = "us-west-2"
}

variable "instanceType" {
  type    = string
  default = "t2.medium"
}

variable "vpcID" {
  type    = string
  default = ""
}