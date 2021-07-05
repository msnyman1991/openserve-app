#AWS Availability zones 
data "aws_availability_zones" "available" {
  state = "available"
}

# Web server AMI
data "aws_ami" "amazon_linux_2" {
  most_recent = true

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-2.0.*x86_64-gp2"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["137112412989"]
}

#Autoscaling launch confguration
resource "aws_launch_configuration" "ec2-launch-config" {
    name          = "ec2-launch-config"
    image_id      = data.aws_ami.amazon_linux_2.id
    instance_type = var.instance_type
    security_groups = aws_security_group.code-test-allow-all.name
    user_data = templatefile("${path.module}/init.tpl", {
        git_revision              = var.git_revision
        api_url                   = var.api_url
        sentry_dsn                = var.sentry_dsn
        social_sharing            = var.social_sharing_enabled
        staging_environment       = var.staging_environment
        redis_url                 = var.redis_url
        enable_google_analytics   = var.enable_google_analytics
        google_analytics_ua       = var.google_analytics_ua
        enable_internal_analytics = var.enable_internal_analytics
        })
}

#Autoscaling group
resource "aws_autoscaling_group" "ec2-autoscaling-group" {
  name                      = "ec2-autoscaling-group"
  max_size                  = 2
  min_size                  = 1
  health_check_grace_period = 100
  health_check_type         = "EC2"
  force_delete              = true
  launch_configuration      = aws_launch_configuration.ec2-launch-config.name
  vpc_zone_identifier       = module.vpc.vpc_id
  tag {
    propagate_at_launch = false
  }
}

#Autoscaling policy out
resource "aws_autoscaling_policy" "ec2-cpu-policy-out" {
  name                   = "ec2-cpu-policy-out"
  scaling_adjustment     = 1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 300
  autoscaling_group_name = aws_autoscaling_group.ec2-autoscaling-group.name
  policy_type            = "SimpleScaling"
}

#Cloudwatch metric alarm out
resource "aws_cloudwatch_metric_alarm" "ec2-cpu-alarm-out" {
  alarm_name          = "ec2-cpu-alarm-out"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "120"
  statistic           = "Average"
  threshold           = "80"

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.ec2-autoscaling-group.name
  }
  actions_enabled   = true
  alarm_description = "This metric monitors ec2 cpu utilization"
  alarm_actions     = aws_autoscaling_policy.ec2-cpu-policy-out.arn
}

#Autoscaling policy in
resource "aws_autoscaling_policy" "ec2-cpu-policy-in" {
  name                   = "ec2-cpu-policy-in"
  scaling_adjustment     = -1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 60
  autoscaling_group_name = aws_autoscaling_group.ec2-autoscaling-group.name
  policy_type            = "SimpleScaling"
}

#Cloudwatch metric alarm in
resource "aws_cloudwatch_metric_alarm" "ec2-cpu-alarm-in" {
  alarm_name          = "ec2-cpu-alarm-in"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "120"
  statistic           = "Average"
  threshold           = "20"

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.ec2-autoscaling-group.name
  }
  actions_enabled   = true
  alarm_description = "This metric monitors ec2 cpu utilization"
  alarm_actions     = aws_autoscaling_policy.ec2-cpu-policy-in.arn
}