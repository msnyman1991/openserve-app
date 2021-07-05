#ALB
resource "aws_lb" "ec2-alb" {
  name               = "ec2-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = aws_security_group.alb-sg.id
  subnets            = module.vpc.public_subnets

  access_logs {
    bucket  = aws_s3_bucket.alb-logs.name
    prefix  = "logs"
    enabled = true
  }
}

#ALB target group
resource "aws_lb_target_group" "alb-target-group" {
  name     = "alb-target-group"
  port     = 8081
  protocol = "HTTP"
  vpc_id   = module.vpc.vpc_id
  target_type = "ip"

  health_check {
    healthy_threshold   = "3"
    interval            = "30"
    protocol            = "HTTP"
    matcher             = "200"
    timeout             = "3"
    path                = "/health"
    unhealthy_threshold = "2"
  }
}

#ALB listener
resource "aws_lb_listener" "alb-listener" {
  load_balancer_arn = aws_lb.ec2-alb.arn
  port              = "443"
  protocol          = "HTTPS"

  default_action {
    type             = "redirect"
    redirect {
      port        = 443
      protocol    = "HTTPS"
      status_code = "HTTP_301"
   }
  }
}

resource "aws_appautoscaling_target" "ecs_target" {
  max_capacity       = 4
  min_capacity       = 1
  resource_id        = "service/${aws_ecs_cluster.ecs-cluster.name}/${aws_ecs_service.ecs-service.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}