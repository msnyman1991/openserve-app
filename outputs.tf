#VPC outputs
output "vpc_id" {
  description = "The ID of the VPC"
  value       = module.vpc.vpc_id
}

output "public_subnets" {
  description = "List of IDs of public subnets"
  value       = module.vpc.public_subnets
}

output "private_subnets" {
  description = "List of IDs of private subnets"
  value       = module.vpc.private_subnets
}

output "ec2-autoscaling-group" {
  value = aws_autoscaling_group.ec2-autoscaling-group.id
}

#ALB outputs
output "alb-target-group" {
  description = "the arn of the ALB target group"
  value = aws_lb_target_group.alb-target-group.arn
}

#ECS outputs
output "ecs-cluster" {
  description = "The name of the ECS cluster"
  value = aws_ecs_cluster.ecs-cluster.name
}

output "ecs-service" {
  description = "The name of the ECS service"
  value = aws_ecs_service.ecs-service.name
}

#Security group outputs
output "ecs-tasks-sg" {
  description = "The security group id of the ECS task group"
  value = aws_security_group.ecs-tasks-sg.id
}

output "alb-sg" {
  description = "The id of the ALB security group"
  value = aws_security_group.alb-sg.id
}

#IAM outputs
output "ecs-task-execution-role" {
  description = "The arn of the ECS task execution IAM role"
  value = aws_iam_role.ecs-task-execution-role.arn
}

output "ecs-tasks-role" {
  description = "The arn of the ECS task IAM role"
  value = aws_iam_role.ecs-task-role.arn
}

#S3 outputs
output "alb-logs" {
  description = "The bucket name where the ALB logs are stored"
  value = aws_s3_bucket.alb-logs.name
}

output "state-tf" {
  description = "The bucket name where the Terraform state is stored"
  value = aws_s3_bucket.state-tf.name
}