terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

provider "aws" {
  region = "ap-south-1"
}

# Default VPC
data "aws_vpc" "default" {
  default = true
}

# Default Subnets
data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

# Security Group
resource "aws_security_group" "mobile_backend_sg" {
  name        = "mobile-backend-sg"
  description = "Security group for mobile backend"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# EC2 - Cloud Backend
resource "aws_instance" "mobile_backend" {
  ami           = "ami-0f918f7e67a3323f0"
  instance_type = "t3.micro"

  subnet_id = data.aws_subnets.default.ids[0]

  vpc_security_group_ids = [
    aws_security_group.mobile_backend_sg.id
  ]

  tags = {
    Name = "Mobile-Backend-Server"
  }
}

# S3 - Cloud Storage
resource "aws_s3_bucket" "mobile_backend_storage" {
  bucket_prefix = "mobile-backend-storage-"

  tags = {
    Name = "Mobile Backend Storage"
  }
}

# RDS PostgreSQL - Cloud Database
resource "aws_db_subnet_group" "mobile_backend_db_subnet" {
  name       = "mobile-backend-db-subnet"
  subnet_ids = data.aws_subnets.default.ids

  tags = {
    Name = "Mobile Backend DB Subnet"
  }
}

resource "aws_db_instance" "mobile_backend_db" {
  identifier        = "mobile-backend-db"
  engine            = "postgres"
  engine_version    = "17"
  instance_class    = "db.t3.micro"
  allocated_storage = 20

  db_name  = "mobileapp"
  username = "adminuser"
  password = "MobileBackend12345"

  db_subnet_group_name   = aws_db_subnet_group.mobile_backend_db_subnet.name
  publicly_accessible    = false
  skip_final_snapshot    = true
  deletion_protection    = false

  tags = {
    Name = "Mobile Backend PostgreSQL"
  }
}