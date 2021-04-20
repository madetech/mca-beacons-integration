resource "aws_alb" "main" {
  name            = "${var.env}-beacons"
  subnets         = aws_subnet.public.*.id
  security_groups = [aws_security_group.lb.id]
}

# TODO: Update this listener to redirect all traffic to 443
resource "aws_alb_listener" "front_end" {
  load_balancer_arn = aws_alb.main.id
  port              = 80
  protocol          = "HTTP"

  default_action {
    target_group_arn = aws_alb_target_group.webapp.id
    type             = "forward"
  }
}

resource "aws_lb_listener_rule" "service" {
  listener_arn = aws_alb_listener.front_end.arn

  action {
    type             = "forward"
    target_group_arn = aws_alb_target_group.service.arn
  }

  condition {
    path_pattern {
      values = ["/spring-api/*"]
    }
  }
}

resource "aws_alb_target_group" "webapp" {
  name        = "${var.env}-webapp-target-group"
  port        = var.webapp_port
  protocol    = "HTTP"
  vpc_id      = aws_vpc.main.id
  target_type = "ip"

  health_check {
    healthy_threshold   = "3"
    interval            = "30"
    protocol            = "TCP"
    timeout             = "3"
    port                = "3000"
    unhealthy_threshold = "2"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_alb_target_group" "service" {
  name        = "${var.env}-service-target-group"
  port        = var.service_port
  protocol    = "HTTP"
  vpc_id      = aws_vpc.main.id
  target_type = "ip"

  health_check {
    healthy_threshold   = "6"
    interval            = "30"
    protocol            = "HTTP"
    matcher             = "200"
    timeout             = "10"
    path                = var.service_health_check_path
    unhealthy_threshold = "6"
  }

  lifecycle {
    create_before_destroy = true
  }
}
