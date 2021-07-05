#ALB S3 logging bucket
resource "aws_s3_bucket" "alb-logs" {
  bucket = "alb-logs"
  acl    = "private"
}

#Terraform state bucket
resource "aws_s3_bucket" "state-tf" {
  bucket = "state-tf"
  acl    = "private"
}