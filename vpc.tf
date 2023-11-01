resource "aws_default_vpc" "default" {
  tags = {
    Name = "Default VPC"
  }
}

data "aws_availability_zones" "available" {
  state = "available"
}

resource "aws_default_subnet" "public" {
  count             = var.az_count
  availability_zone = data.aws_availability_zones.available.names[count.index]

  tags = {
    Name = "Default subnet for ${data.aws_availability_zones.available.names[count.index]}"
  }
}

resource "aws_subnet" "private" {
  count             = var.az_count
  availability_zone = data.aws_availability_zones.available.names[count.index]
  vpc_id            = aws_default_vpc.default.id
  cidr_block        = cidrsubnet(aws_default_vpc.default.cidr_block, 4, 8 + count.index)

  tags = {
    Name = "Private subnet for ${data.aws_availability_zones.available.names[count.index]}"
  }
}

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
