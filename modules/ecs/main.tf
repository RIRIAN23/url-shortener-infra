# TODO: ADD MISSING SECRETS
locals {
  api_cache_secrets = [
    {
      name      = "DYNAMODB_TABLE"
      valueFrom = var.ssm_dynamodb_table_arn
    },
    {
      name      = "DYNAMODB_REGION"
      valueFrom = var.ssm_dynamodb_region_arn
    },
  ]


  # api service
  api_base_secrets = [
    {
      name      = "BASE_URL"
      valueFrom = var.ssm_base_url_arn
    },
    {
      name      = "SQS_URL"
      valueFrom = var.ssm_sqs_url_arn
    },
    {
      name      = "DATABASE_URL"
      valueFrom = var.ssm_db_url_arn
    },
  ]

  api_secrets = concat(local.api_base_secrets, local.api_cache_secrets)

  # analytics service
  analytics_secrets = [
    {
      name      = "SQS_URL"
      valueFrom = var.ssm_sqs_url_arn
    },
    {
      name      = "DATABASE_URL"
      valueFrom = var.ssm_db_url_arn
    },
  ]
}

# ECS Cluster
# TODO: ADD MISSING KEYS AND VALUES TO RESOURCE BELOW
resource "aws_ecs_cluster" "main" {
  name = var.cluster_name

  tags = {
    Name    = var.cluster_name
    Project = "lks-url"
  }
}

# TODO: ADD MISSING KEYS AND VALUES TO RESOURCE BELOW
resource "aws_ecs_task_definition" "api" {
  family                   = "lks-url-api-td"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = 512
  memory                   = 1024
  execution_role_arn       = var.lab_role_arn
  task_role_arn            = var.lab_role_arn

  container_definitions = jsonencode([
    {
      name      = "shorener-api"
      image     = var.ecr_api_url
      essential = true

      # TODO: SET PROPER PORT
      portMappings = [
        {
          containerPort = 3000
          hostPort      = 3000
        }
      ]

      secrets = local.api_secrets

      # TODO: SET PROPER ENVIRONMENT
      environment = [
        {
          APP_ENV = "production"
        }
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = var.log_group_api
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "ecs"
        }
      }
    }
  ])

  tags = {
    Name    = "lks-url-api-td"
    Project = "lks-url"
  }
}

# api service
# TODO: ADD MISSING KEYS AND VALUES TO RESOURCE BELOW
resource "aws_ecs_service" "api" {
  name            = "lks-url-api-svc"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.api.id
  desired_count   = 2
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = var.private_subnet_ids
    security_groups  = [var.ecs_sg_id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = var.tg_api_arn
    container_name   = "shorener-api"
    container_port   = 3000
  }

  tags = {
    Name    = "lks-url-api-svc"
    Project = "lks-url"
  }
}

# analytics service
# TODO: ADD MISSING KEYS AND VALUES TO RESOURCE BELOW
resource "aws_ecs_task_definition" "analytics" {
  family                   = "lks-url-analytics-td"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = 512
  memory                   = 1024
  execution_role_arn       = var.lab_role_arn
  task_role_arn            = var.lab_role_arn

  container_definitions = jsonencode([
    {
      name      = "analytics-svc"
      image     = var.ecr_analytics_url
      essential = true

      # TODO: SET PROPER PORT
      portMappings = [
        {
          containerPort = 3001
          hostPort      = 3001
        }
      ]

      secrets = local.analytics_secrets

      # TODO: SET PROPER ENV
      environment = [
        {
          APP_ENV = "production"
        }
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = var.log_group_analytics
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "ecs"
        }
      }
    }
  ])

  tags = {
    Name    = "lks-url-analytics-td"
    Project = "lks-url"
  }
}

# TODO: ADD MISSING KEYS AND VALUES TO RESOURCE BELOW
resource "aws_ecs_service" "analytics" {
  name            = "lks-url-analytics-svc"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.analytics.id
  desired_count   = 2
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = var.private_subnet_ids
    security_groups  = [var.ecs_sg_id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = var.tg_analytics_arn
    container_name   = "analytics-svc"
    container_port   = 3001
  }

  tags = {
    Name    = "lks-url-analytics-svc"
    Project = "lks-url"
  }
}

# frontend service
# TODO: ADD MISSING KEYS AND VALUES TO RESOURCE BELOW
resource "aws_ecs_task_definition" "frontend" {
  family                   = "lks-url-frontend-td" 
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = 256
  memory                   = 512
  execution_role_arn       = var.lab_role_arn
  task_role_arn            = var.lab_role_arn

  container_definitions = jsonencode([
    {
      name      = "frontend"
      image     = var.ecr_frontend_url
      essential = true

      # TODO: SET PROPER PORT
      portMappings = [
        {
          containerPort = 80
          hostPort      = 80
        }
      ]

      secrets     = []
      environment = []

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = var.log_group_frontend
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "ecs"
        }
      }
    }
  ])

  tags = {
    Name    = "lks-url-frontend-td"
    Project = "lks-url"
  }
}

# TODO: ADD MISSING KEYS AND VALUES TO RESOURCE BELOW
resource "aws_ecs_service" "frontend" {
  name            = "lks-url-frontend-svc"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.frontend.id
  desired_count   = 2
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = var.private_subnet_ids
    security_groups  = [var.ecs_sg_id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = var.tg_frontend_arn
    container_name   = "frontend"
    container_port   = 80
  }

  tags = {
    Name    = "lks-url-frontend-svc"
    Project = "lks-url"
  }
}
