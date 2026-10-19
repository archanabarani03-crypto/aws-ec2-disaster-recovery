variable "aws_region" {
  type    = string
  default = "ap-south-1"
}

variable "project_name" {
  type    = string
  default = "ec2-dr-lab"
}

variable "instance_type" {
  type    = string
  default = "t3.micro"
}

variable "ssh_cidr" {
  type    = string
  default = ""
}

variable "key_name" {
  type    = string
  default = ""
}

variable "backup_prefix" {
  type    = string
  default = "application-data/"
}
