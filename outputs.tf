output "vpc_id" {
  description = "ID of the VPC created by Terraform"
  value       = module.vpc.vpc_id
}

output "public_subnet_ids" {
  value = module.vpc.public_subnet_ids
}

output "private_subnet_ids" {
  value = module.vpc.private_subnet_ids
}

output "web_public_ip" {
  value = aws_eip.web.public_ip
}

output "web_url" {
  value = "http://${aws_eip.web.public_ip}"
}
output "web_instance_id" {
  value = aws_instance.web.id
}