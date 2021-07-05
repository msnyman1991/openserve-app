#VPC outputs
output "vpc_id" {
  description = "The ID of the VPC"
  value       = module.vpc.vpc_id
}

output "public_subnets" {
  description = "List of IDs of public subnets"
  value       = module.vpc.public_subnets
}

output "ec2-autoscaling-group" {
  description = "The id of the auto scaling group"
  value = aws_autoscaling_group.ec2-autoscaling-group.id
}

#S3 outputs
output "alb-logs" {
  description = "The name of the s3 bucket for ALB logs"
  value = aws_s3_bucket.alb-logs.name
}

output "state-tf" {
  description = "The name of the s3 bucket for storing Terraform state"
  value = aws_s3_bucket.state-tf.name
}

#Security group outputs
output "code-test-allow-all" {
  description = "The id of the security group for the EC2 instances"
  value = aws_security_group.code-test-allow-all.name
}