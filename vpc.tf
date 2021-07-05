#AWS VPC
module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = "openverse-vpc"
  cidr = "10.0.0.0/16"

  azs             = ["us-east-1a", "us-east-1b", "us-east-1c"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]
}

#AWS internet gateway
resource "aws_internet_gateway" "internet-gw" {
  vpc_id = module.vpc.vpc_id
}

#AWS public subnet route table
resource "aws_route_table" "public-route-table" {
  vpc_id = module.vpc.vpc_id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.internet-gw.id
  }
}

#AWS public subnet route table association
resource "aws_route_table_association" "public-route-table-association" {
  subnet_id      = module.vpc.public_subnets
  route_table_id = aws_route_table.public-route-table.id
}
