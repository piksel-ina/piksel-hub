# --- Fetch AMI ---
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

}

# --- Security Group to allow SSH access ---
resource "aws_security_group" "ec2_sg" {
  count       = (var.create_test_target_ec2) ? 1 : 0
  name        = "ec2-sg"
  description = "Security Group for EC2 instances with SSH access"
  vpc_id      = var.vpc_id

  ingress {
    description = "ICMP from VPC"
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "HTTP from VPC"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "ec2-sg-for-testing"
  }
}


# --- Test Target EC2: Test DNS resolution and network traffic through TGW" 
resource "aws_instance" "dev_test_target_ec2" {
  count                  = var.create_test_target_ec2 ? 1 : 0
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.test_instance_type
  subnet_id              = var.subnet_id_target
  vpc_security_group_ids = [aws_security_group.ec2_sg[0].id]
  private_ip             = "10.0.15.200"

  user_data = <<-EOF
              #!/bin/bash
              echo "nameserver 169.254.169.253" > /etc/resolv.conf
              apt-get update
              apt-get install -y dnsutils curl nginx
              systemctl start nginx
              systemctl enable nginx
              echo "<h1>Test Target - Shared VPC (10.0.15.200)</h1>" > /var/www/html/index.nginx-debian.html
              EOF

  tags = {
    Name = "test-target-ec2"
  }
}

# --- Variables ---
variable "vpc_id" {
  description = "VPC ID"
}

variable "create_test_target_ec2" {
  description = "Boolean to control whether to create the test target EC2 instance"
  type        = bool
  default     = false
}

variable "test_instance_type" {
  description = "EC2 instance type for testing instance"
  default     = "t3.micro"
}

variable "subnet_id_target" {
  description = "Subent id of the Recorded IP Adress resides (test target EC2) "
}

# --- Outputs ---
output "test_target_ec2_ip" {
  description = "Private IP of the Dev VPC test target EC2 instance"
  value       = var.create_test_target_ec2 ? aws_instance.dev_test_target_ec2[0].private_ip : "Not created"
}


# --- Providers ---
terraform {
  required_version = ">= 1.11.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "= 5.95"
    }
  }
}
