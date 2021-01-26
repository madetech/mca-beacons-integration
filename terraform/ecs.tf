resource "aws_ecs_cluster" "main" {
  name = "mca-beacons-cluster"
}

resource "aws_ecs_task_definition" "webapp" {
  family                   = "beacons-webapp-task"
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.webapp_fargate_cpu
  memory                   = var.webapp_fargate_memory
  container_definitions = jsonencode([{
    "name" : "beacons-webapp",
    "image" : var.webapp_image,
    "portMappings" : [
      {
        "containerPort" : var.webapp_port
        "hostPort" : var.webapp_port
      }
    ],
    "logConfiguration" : {
      "logDriver" : "awslogs",
      "options" : {
        "awslogs-group" : aws_cloudwatch_log_group.log_group.name,
        "awslogs-region" : var.aws_region,
        "awslogs-stream-prefix" : "webapp"
      }
    }
  }])
}

resource "aws_ecs_service" "webapp" {
  name            = "beacons-webapp"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.webapp.arn
  desired_count   = var.webapp_count
  launch_type     = "FARGATE"

  network_configuration {
    security_groups  = [aws_security_group.ecs_tasks.id]
    subnets          = aws_subnet.private.*.id
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = aws_alb_target_group.webapp.id
    container_name   = "beacons-webapp"
    container_port   = var.webapp_port
  }

  depends_on = [aws_alb_listener.front_end, aws_iam_role_policy_attachment.ecs_task_execution_role]
}

resource "aws_ecs_task_definition" "service" {
  family                   = "beacons-service-task"
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.service_fargate_cpu
  memory                   = var.service_fargate_memory
  container_definitions = jsonencode([{
    "name" : "beacons-service",
    "image" : var.service_image,
    "portMappings" : [
      {
        "containerPort" : var.service_port
        "hostPort" : var.service_port
      }
    ],
    "logConfiguration" : {
      "logDriver" : "awslogs",
      "options" : {
        "awslogs-group" : aws_cloudwatch_log_group.log_group.name,
        "awslogs-region" : var.aws_region,
        "awslogs-stream-prefix" : "service"
      }
    }
  }])
}

resource "aws_ecs_service" "service" {
  name            = "beacons-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.service.arn
  desired_count   = var.service_count
  launch_type     = "FARGATE"

  network_configuration {
    security_groups  = [aws_security_group.ecs_tasks.id]
    subnets          = aws_subnet.private.*.id
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = aws_alb_target_group.service.id
    container_name   = "beacons-service"
    container_port   = var.service_port
  }

  depends_on = [aws_alb_listener.front_end, aws_iam_role_policy_attachment.ecs_task_execution_role]
}