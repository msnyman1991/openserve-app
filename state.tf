#Terrafrom S3 state
terraform {
  backend "s3" {
  encrypt = true 
  bucket = aws_s3_bucket.state-tf.name 
  region = "us-east-1"
  key = "terraform_state"
    }
}