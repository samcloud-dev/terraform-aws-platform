variable "aws_region" {
  description = "AWS region where infrastructure will be deployed"
  type        = string
  default     = "ca-central-1"
}

variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = "terraform-aws-platform"
}

variable "environment" {
  description = "Deployment environment"
  type        = string
  default     = "dev"
}

variable "vpc_cidr" {
  description = "CIDR block for the project VPC"
  type        = string
  default     = "10.0.0.0/16"
}
variable "instance_type" {
  description = "EC2 size: t3.small while learning, m7i-flex.large for k3s + FreshTrack"
  type        = string
  default     = "t3.small"
}

variable "root_volume_size" {
  description = "Root disk size in GiB (container images and PostgreSQL data live here)"
  type        = number
  default     = 30

  validation {
    condition     = var.root_volume_size >= 20 && var.root_volume_size <= 100
    error_message = "root_volume_size must be between 20 and 100 GiB."
  }
}
variable "allowed_ingress_cidr" {
  description = "Who may reach ports 80/443. Your home IP (/32) while building; widened at go-live"
  type        = string

  validation {
    condition     = can(cidrhost(var.allowed_ingress_cidr, 0))
    error_message = "allowed_ingress_cidr must be a CIDR block, for example 203.0.113.45/32."
  }
}