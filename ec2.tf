# Look up the newest Amazon Linux 2023 AMI (the house plan)
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-x86_64"]
  }
}

# The front door lock for our web server
resource "aws_security_group" "web" {
  name        = "web-sg"
  description = "Allow HTTP in, all traffic out"
  vpc_id      = module.vpc.vpc_id

  tags = {
    Name = "web-sg"
  }
}

# Inbound: HTTP, only from the allowed CIDR (redirects to HTTPS later)
resource "aws_vpc_security_group_ingress_rule" "http_in" {
  security_group_id = aws_security_group.web.id
  description       = "HTTP from allowed CIDR"
  cidr_ipv4         = var.allowed_ingress_cidr
  from_port         = 80
  to_port           = 80
  ip_protocol       = "tcp"
}
# Inbound: HTTPS, only from the allowed CIDR
resource "aws_vpc_security_group_ingress_rule" "https_in" {
  security_group_id = aws_security_group.web.id
  description       = "HTTPS from allowed CIDR"
  cidr_ipv4         = var.allowed_ingress_cidr
  from_port         = 443
  to_port           = 443
  ip_protocol       = "tcp"
}

# Outbound rule: the server may go out anywhere (e.g. to download nginx)
resource "aws_vpc_security_group_egress_rule" "all_out" {
  security_group_id = aws_security_group.web.id
  description       = "Allow all outbound"
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}

# The web server (the house)
resource "aws_instance" "web" {
  ami                         = data.aws_ami.amazon_linux.id
  instance_type               = var.instance_type
  subnet_id                   = module.vpc.public_subnet_ids[0]
  vpc_security_group_ids      = [aws_security_group.web.id]
  iam_instance_profile        = aws_iam_instance_profile.web.name
  associate_public_ip_address = true
  # Require IMDSv2: the info desk needs a session token (PIN)
  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
  }

  # Encrypt the server's disk
  root_block_device {
    encrypted   = true
    volume_type = "gp3"
    volume_size = var.root_volume_size
  }


  lifecycle {
    ignore_changes = [ami]
  }

  tags = {
    Name = "web-server"
  }
}
# The fixed phone number (Elastic IP) for the server
resource "aws_eip" "web" {
  domain   = "vpc"               # an Elastic IP for use inside a VPC
  instance = aws_instance.web.id # attach it to our server

  # The gate (IGW) must exist before a public number can work
  depends_on = [module.vpc]

  tags = {
    Name = "${var.project_name}-${var.environment}-web-eip"
  }
}