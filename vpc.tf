## VPCs

resource "aws_default_vpc" "default" {
  tags = {
    Name = "Default VPC"
  }
}

## Subnets

data "aws_availability_zones" "available" {
  state = "available"
}

locals {
  available_azs = data.aws_availability_zones.available.names
}

resource "aws_default_subnet" "public" {
  count             = var.az_count
  availability_zone = local.available_azs[count.index]

  tags = {
    Name = "Default subnet for ${local.available_azs[count.index]}"
  }
}

resource "aws_subnet" "private" {
  count             = var.az_count
  availability_zone = local.available_azs[count.index]
  vpc_id            = aws_default_vpc.default.id
  cidr_block        = cidrsubnet(aws_default_vpc.default.cidr_block, 4, 8 + count.index)

  tags = {
    Name = "Private subnet for ${local.available_azs[count.index]}"
  }
}

## Route tables

resource "aws_route_table" "private" {
  vpc_id = aws_default_vpc.default.id

  tags = {
    Name = "Private route table"
  }
}

resource "aws_route_table_association" "private" {
  count          = var.az_count
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private.id
}

## Security groups

resource "aws_security_group" "alb" {
  name        = "alb"
  description = "SG for ALB"
  vpc_id      = aws_default_vpc.default.id
}

resource "aws_vpc_security_group_ingress_rule" "alb_https" {
  security_group_id = aws_security_group.alb.id

  cidr_ipv4   = "0.0.0.0/0"
  ip_protocol = "tcp"
  from_port   = 443
  to_port     = 443
}

resource "aws_vpc_security_group_ingress_rule" "alb_icmp" {
  security_group_id = aws_security_group.alb.id

  cidr_ipv4   = "0.0.0.0/0"
  ip_protocol = "icmp"
  from_port   = "-1"
  to_port     = "-1"
}

# for OIDC authentication
resource "aws_vpc_security_group_egress_rule" "alb_https" {
  security_group_id = aws_security_group.alb.id

  cidr_ipv4   = "0.0.0.0/0"
  ip_protocol = "tcp"
  from_port   = 443
  to_port     = 443
}
