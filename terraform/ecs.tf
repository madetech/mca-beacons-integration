data "aws_ecr_repository" "webapp" {
  name = var.webapp_image
}

data "aws_ecr_repository" "service" {
  name = var.service_image
}

resource "aws_ecs_cluster" "main" {
  name = "${terraform.workspace}-mca-beacons-cluster"
  tags = module.beacons_label.tags
}

resource "aws_ecs_task_definition" "webapp" {
  tags                     = module.beacons_label.tags
  family                   = "${terraform.workspace}-beacons-webapp-task"
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.webapp_fargate_cpu
  memory                   = var.webapp_fargate_memory
  container_definitions = jsonencode([{
    name : "beacons-webapp",
    image : "${data.aws_ecr_repository.webapp.repository_url}:${var.webapp_image_tag}",
    portMappings : [
      {
        containerPort : var.webapp_port
        hostPort : var.webapp_port
      }
    ],
    environment : [
      {
        name : "API_URL",
        value : "http://${local.service_local_endpoint}"
      },
      {
        name : "WEBAPP_CLIENT_ID",
        value : var.webapp_azure_ad_client_id
      },
      {
        name : "AAD_API_ID",
        value : var.service_azure_ad_api_id
      },
      {
        name : "AAD_TENANT_ID",
        value : var.webapp_azure_ad_tenant_id
      },
      {
        name : "REDIS_URI",
        value : "redis://${aws_elasticache_cluster.main.cache_nodes.*.address}:${var.redis_port}"
      },
      {
        name : "NEXTAUTH_URL",
        value : var.webapp_next_auth_url
      },
      {
        name : "AZURE_B2C_CLIENT_ID",
        value : var.webapp_azure_b2c_client_id
      },
      {
        name : "AZURE_B2C_TENANT_NAME",
        value : var.webapp_azure_b2c_tenant_name
      },
      {
        name : "AZURE_B2C_TENANT_ID",
        value : var.webapp_azure_b2c_tenant_id
      },
      {
        name : "AZURE_B2C_LOGIN_FLOW",
        value : var.webapp_azure_b2c_login_flow
      }
    ],
    logConfiguration : {
      "logDriver" : "awslogs",
      "options" : {
        "awslogs-group" : aws_cloudwatch_log_group.log_group.name,
        "awslogs-region" : var.aws_region,
        "awslogs-stream-prefix" : "webapp"
      }
    },
    secrets : [
      {
        name : "GOV_NOTIFY_API_KEY",
        valueFrom : aws_secretsmanager_secret.gov_notify_api_key.arn
      },
      {
        name : "GOV_NOTIFY_CUSTOMER_EMAIL_TEMPLATE",
        valueFrom : aws_secretsmanager_secret.gov_notify_customer_email_template.arn
      },
      {
        name : "BASIC_AUTH_CREDENTIALS",
        valueFrom : aws_secretsmanager_secret.basic_auth.arn
      },
      {
        name : "WEBAPP_CLIENT_SECRET",
        valueFrom : aws_secretsmanager_secret.webapp_client_secret.arn
      },
      {
        name : "AZURE_B2C_CLIENT_SECRET",
        valueFrom : aws_secretsmanager_secret.b2c_client_secret.arn
      },
      {
        name : "JWT_SECRET",
        valueFrom : aws_secretsmanager_secret.b2c_next_auth_jwt_secret.arn
      }
    ]
  }])
}

resource "aws_ecs_service" "webapp" {
  tags             = module.beacons_label.tags
  name             = "${terraform.workspace}-beacons-webapp"
  cluster          = aws_ecs_cluster.main.id
  task_definition  = aws_ecs_task_definition.webapp.arn
  desired_count    = var.webapp_count
  launch_type      = "FARGATE"
  platform_version = "1.4.0"

  network_configuration {
    security_groups = [aws_security_group.ecs_tasks.id]
    subnets         = aws_subnet.app.*.id
  }

  load_balancer {
    target_group_arn = aws_alb_target_group.webapp.id
    container_name   = "beacons-webapp"
    container_port   = var.webapp_port
  }

  service_registries {
    registry_arn = aws_service_discovery_service.webapp.arn
  }

  depends_on = [aws_alb_listener.front_end, aws_iam_role_policy_attachment.ecs_task_execution_role]
}

resource "aws_ecs_task_definition" "service" {
  tags                     = module.beacons_label.tags
  family                   = "${terraform.workspace}-beacons-service-task"
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.service_fargate_cpu
  memory                   = var.service_fargate_memory
  container_definitions = jsonencode([{
    name : "beacons-service",
    image : "${data.aws_ecr_repository.service.repository_url}:${var.service_image_tag}",
    portMappings : [
      {
        containerPort : var.service_port
        hostPort : var.service_port
      }
    ],
    environment : [
      {
        name : "SPRING_DATASOURCE_URL",
        value : "jdbc:postgresql://${aws_db_instance.postgres.endpoint}/${var.db_name}?sslmode=require"
      },
      {
        name : "SPRING_DATASOURCE_USER",
        value : var.db_username
      }
    ],
    logConfiguration : {
      "logDriver" : "awslogs",
      "options" : {
        "awslogs-group" : aws_cloudwatch_log_group.log_group.name,
        "awslogs-region" : var.aws_region,
        "awslogs-stream-prefix" : "service"
      }
    },
    secrets : [
      {
        name : "SPRING_DATASOURCE_PASSWORD",
        valueFrom : aws_secretsmanager_secret.db_password.arn
    }]
  }])
}

resource "aws_ecs_service" "service" {
  tags             = module.beacons_label.tags
  name             = "${terraform.workspace}-beacons-service"
  cluster          = aws_ecs_cluster.main.id
  task_definition  = aws_ecs_task_definition.service.arn
  desired_count    = var.service_count
  launch_type      = "FARGATE"
  platform_version = var.ecs_fargate_version

  network_configuration {
    security_groups = [aws_security_group.ecs_tasks.id]
    subnets         = aws_subnet.app.*.id
  }

  load_balancer {
    target_group_arn = aws_alb_target_group.service.id
    container_name   = "beacons-service"
    container_port   = var.service_port
  }

  service_registries {
    registry_arn = aws_service_discovery_service.service.arn
  }

  depends_on = [aws_alb_listener.front_end, aws_iam_role_policy_attachment.ecs_task_execution_role]
}
