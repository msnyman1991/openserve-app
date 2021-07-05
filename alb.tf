#ALB security group
resource "aws_security_group" "alb-sg" {
  name = "alb-sg"

  ingress {
    cidr_blocks = ["0.0.0.0/0"]
    from_port = 22
    to_port = 22
    protocol = "tcp"
  }

  ingress {
    cidr_blocks = ["0.0.0.0/0"]
    from_port = 80
    to_port = 80
    protocol = "tcp"
  }

  ingress {
    cidr_blocks = ["0.0.0.0/0"]
    from_port = 8081
    to_port = 8081
    protocol = "tcp"
  }

 ingress {
    cidr_blocks = ["0.0.0.0/0"]
    from_port = 8080
    to_port = 8080
    protocol = "tcp"
  }
}

#ALB
resource "aws_lb" "ec2-alb" {
  name               = "ec2-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = aws_security_group.alb-sg
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
}

#ALB listener
resource "aws_lb_listener" "alb-listener" {
  load_balancer_arn = aws_lb.ec2-alb.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = "arn:aws:iam::187416307283:server-certificate/test_cert_rab3wuqwgja25ct3n4jdj2tzu4"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.alb-target-group.arn
  }
}

#ALB listener rule
resource "aws_lb_listener_rule" "alb-listener-rule" {
  listener_arn = aws_lb_listener.alb-listener-rule.arn
  priority     = 100

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.alb-target-group.arn
  }

  condition {
    path_pattern {
      values = ["/static/*"]
    }
  }

  condition {
    host_header {
      values = ["example.com"]
    }
  }
}

#ALB autoscaling attachment
resource "aws_autoscaling_attachment" "alb-autoscaling-group-attachment" {
  autoscaling_group_name = aws_autoscaling_group.ec2-autoscaling-group.id
  alb_target_group_arn   = aws_lb_target_group.alb-target-group.arn
}