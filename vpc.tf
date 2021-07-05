#VPC
module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = "openverse-vpc"
  cidr = "10.0.0.0/16"

  azs             = ["us-east-1a", "us-east-1b", "us-east-1c"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
}

#internet gateway
resource "aws_internet_gateway" "internet-gw" {
  vpc_id = module.vpc.vpc_id
}

#public subnet route table
resource "aws_route_table" "public-route-table" {
  vpc_id = module.vpc.vpc_id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.internet-gw.id
  }
}

#Public subnet route table association
resource "aws_route_table_association" "public-route-table-association" {
  subnet_id      = module.vpc.public_subnets
  route_table_id = aws_route_table.public-route-table.id
}

#NAT Gateway
resource "aws_nat_gateway" "nat-gw" {
  allocation_id = aws_eip.nat-gw-eip.id
  subnet_id     = module.vpc.public_subnets
}

#EIP for NAT Gateway
resource "aws_eip" "nat-gw-eip" {
  count = length(module.vpc.private_subnets)
  vpc = true
}

#Private subnet route table
resource "aws_route_table" "private-route-table" {
  vpc_id = module.vpc.vpc_id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.nat-gw.id
  }
}

#Private subnet route table association
resource "aws_route_table_association" "private-route-table-association" {
  subnet_id      = module.vpc.private_subnets
  route_table_id = aws_route_table.private-route-table.id
}