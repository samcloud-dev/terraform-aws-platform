
variable "vpc_cidr" {
  description = "CIDR block for the VPC, e.g. 10.0.0.0/16"
  type        = string

  validation {
    condition     = can(cidrhost(var.vpc_cidr, 0))
    error_message = "vpc_cidr must be a valid CIDR block, for example 10.0.0.0/16."
  }
}

variable "project_name" {
  description = "Name of the project, used as a prefix in resource names"
  type        = string
}

variable "environment" {
  description = "Deployment environment (e.g. dev, staging), used as a prefix in resource names"
  type        = string
}