# TODO: ADD MISSING VALUES TO RESOURCES BELOW

locals {
  tags = { Project = "lks-url" }
}

resource "aws_db_subnet_group" "main" {
  name       = "lks-url-db-subnet-group"
  subnet_ids = var.private_subnet_ids

  tags = merge(local.tags, { Name = "lks-url-db-subnet-group" })
}

# TODO: ADD PROPER KEYS AND VALUES TO RESOURCE BELOW
resource "aws_db_instance" "main" {
  allocated_storage    = 20
  db_name              = "urlshortener"
  engine               = "postgres"
  engine_version       = "17"
  instance_class       = "db.t3.micro"
  username             = var.db_username
  password             = var.db_password
  skip_final_snapshot  = true
  db_subnet_group_name = aws_db_subnet_group.main.id
  vpc_security_group_ids = [var.rds_sg_id]
  publicly_accessible = false
  identifier          = "lks-url-db"

  tags = merge(local.tags, { Name = "lks-url-db" })
}
