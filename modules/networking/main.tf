locals {
  tags = {
    Project = "lks-url"
  }
}

# VPC
# TODO: ADD MISSING KEYS AND VALUES TO RESOURCE BELOW
resource "aws_vpc" "main" {
  cidr_block           = "172.16.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = merge(local.tags, { Name = "lks-url-vpc" })
}

# Internet Gateway
# TODO: ADD MISSING KEYS AND VALUES TO RESOURCE BELOW
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id

  tags = merge(local.tags, { Name = "lks-url-igw" })
}

# Subnets
# TODO: ADD MISSING KEYS AND VALUES TO RESOURCE BELOW
resource "aws_subnet" "public_a" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "172.16.1.0/24"
  availability_zone = "us-east-1a"
  map_public_ip_on_launch = true

  tags = merge(local.tags, { Name = "lks-url-public-subnet-a" })
}

# TODO: ADD MISSING KEYS AND VALUES TO RESOURCE BELOW
resource "aws_subnet" "public_b" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "172.16.2.0/24"
  availability_zone = "us-east-1b"
  map_public_ip_on_launch = "true"

  tags = merge(local.tags, { Name = "lks-url-public-subnet-b" })
}

# TODO: ADD MISSING KEYS AND VALUES TO RESOURCE BELOW
resource "aws_subnet" "private_a" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "172.16.11.0/24"
  availability_zone = "us-east-1a"

  tags = merge(local.tags, { Name = "lks-url-private-subnet-a" })
}

# TODO: ADD MISSING KEYS AND VALUES TO RESOURCE BELOW
resource "aws_subnet" "private_b" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "172.16.12.0/24"
  availability_zone = "us-east-1b"

  tags = merge(local.tags, { Name = "lks-url-private-subnet-b" })
}

# NAT Gateway
# TODO: ADD MISSING KEYS AND VALUES TO RESOURCE BELOW
resource "aws_eip" "nat" {
  domain   = "vpc"

  tags = merge(local.tags, { Name = "lks-url-nat-eip" })
}

resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public_a.id

  tags = merge(local.tags, { Name = "lks-url-nat" })

  depends_on = [aws_internet_gateway.igw]
}

# Route Tables
# TODO: ADD MISSING KEYS AND VALUES TO RESOURCE BELOW
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = merge(local.tags, { Name = "lks-url-public-rt" })
}

# TODO: ADD MISSING KEYS AND VALUES TO RESOURCE BELOW
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat.id
  }

  tags = merge(local.tags, { Name = "lks-url-private-rt" })
}

# TODO: ADD MISSING KEYS AND VALUES TO RESOURCE BELOW
resource "aws_route_table_association" "public_a" {
  subnet_id      = aws_subnet.public_a.id
  route_table_id = aws_route_table.public.id
}

# TODO: ADD MISSING KEYS AND VALUES TO RESOURCE BELOW
resource "aws_route_table_association" "public_b" {
  subnet_id      = aws_subnet.public_b.id
  route_table_id = aws_route_table.public.id
}

# TODO: ADD MISSING KEYS AND VALUES TO RESOURCE BELOW
resource "aws_route_table_association" "private_a" {
  subnet_id      = aws_subnet.private_a.id
  route_table_id = aws_route_table.private.id
}

# TODO: ADD MISSING KEYS AND VALUES TO RESOURCE BELOW
resource "aws_route_table_association" "private_b" {
  subnet_id      = aws_subnet.private_b.id
  route_table_id = aws_route_table.private.id
}

# Security Groups
# TODO: ADD MISSING KEYS AND VALUES TO RESOURCE BELOW
resource "aws_security_group" "alb" {
  name        = "lks-url-alb-sg"
  description = "exposes the standard web service port to all public users"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  ingress {
    from_port        = 443
    to_port          = 443
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  tags = merge(local.tags, { Name = "lks-url-alb-sg" })
}

# TODO: ADD MISSING KEYS AND VALUES TO RESOURCE BELOW
resource "aws_security_group" "ecs" {
  name        = "lks-url-ecs-sg"
  description = "permit inbound traffic on the standard web port as well as ports 3000 and 3001 that are utilized by the application"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    security_groups  = [aws_security_group.alb.id]
  }

  ingress {
    from_port        = 3000
    to_port          = 3001
    protocol         = "tcp"
    security_groups  = [aws_security_group.alb.id]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  tags = merge(local.tags, { Name = "lks-url-ecs-sg" })
}

# TODO: ADD MISSING KEYS AND VALUES TO RESOURCE BELOW
resource "aws_security_group" "rds" {
  name        = "lks-url-rds-sg"
  description = "Access should be constrained to the default port of the database engine, accepting traffic exclusively from the application tier"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port        = 5432
    to_port          = 5432
    protocol         = "tcp"
    security_groups  = [aws_security_group.ecs.id]
  }

  tags = merge(local.tags, { Name = "lks-url-rds-sg" })
}