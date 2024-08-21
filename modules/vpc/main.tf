resource "aws_vpc" "shoora" {
  cidr_block           = var.cidr_block
  enable_dns_support   = var.enable_dns_support
  enable_dns_hostnames = var.enable_dns_hostnames

  tags = var.tags
}

# resource "aws_cloudwatch_log_group" "shoora" {
#   name_prefix = var.log_group_prefix

#   tags = var.tags

#   lifecycle {
#     create_before_destroy = true
#   }
# }

# resource "aws_flow_log" "shoora" {
#   iam_role_arn    = var.vpc_log_iam_role_arn
#   log_destination = aws_cloudwatch_log_group.shoora.arn
#   traffic_type    = "ALL"
#   vpc_id          = aws_vpc.shoora.id

#   tags = var.tags
# }

resource "aws_internet_gateway" "shoora" {
  vpc_id = aws_vpc.shoora.id

  tags = var.tags
}

resource "aws_default_route_table" "shoora" {
  default_route_table_id = aws_vpc.shoora.default_route_table_id

  tags = var.tags
}

resource "aws_route" "shoora_internet" {
  route_table_id         = aws_default_route_table.shoora.default_route_table_id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.shoora.id
}

resource "aws_subnet" "shoora" {
  count = length(var.aws_availability_zones)

  vpc_id            = aws_vpc.shoora.id
  availability_zone = element(var.aws_availability_zones, count.index)
  cidr_block        = cidrsubnet(var.cidr_block, 8, count.index)

  tags = merge(
    var.tags,
    var.public_subnet_tags,
    {
      Name = "${var.subnet_tag}-public-${count.index + 1}"
    }
  )
}

resource "aws_route_table_association" "shoora" {
  count = length(aws_subnet.shoora.*.id)

  subnet_id      = element(aws_subnet.shoora.*.id, count.index)
  route_table_id = aws_default_route_table.shoora.id
}

resource "aws_eip" "shoora_private" {
  count = var.private_subnet_enabled ? 1 : 0

  domain = "vpc"

  tags = var.tags
}

resource "aws_nat_gateway" "shoora_private" {
  count = var.private_subnet_enabled ? 1 : 0

  allocation_id = aws_eip.shoora_private[0].id
  subnet_id     = aws_subnet.shoora[0].id

  tags = var.tags

  depends_on = [
    aws_internet_gateway.shoora
  ]
}

resource "aws_route_table" "shoora_private" {
  count = var.private_subnet_enabled ? 1 : 0

  vpc_id = aws_vpc.shoora.id

  tags = merge(
    var.tags,
    {
      Name = "${var.subnet_tag}-private"
    }
  )
}

resource "aws_route" "shoora_private" {
  count = var.private_subnet_enabled ? 1 : 0

  route_table_id         = aws_route_table.shoora_private[0].id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.shoora_private[0].id
}

resource "aws_subnet" "shoora_private" {
  count = var.private_subnet_enabled ? length(var.aws_availability_zones) : 0

  vpc_id            = aws_vpc.shoora.id
  availability_zone = element(var.aws_availability_zones, count.index)
  cidr_block        = cidrsubnet(var.cidr_block, 4, count.index + 1)

  tags = merge(
    var.tags,
    var.private_subnet_tags,
    {
      Name = "${var.subnet_tag}-private-${count.index + 1}"
    }
  )

  depends_on = [aws_subnet.shoora]
}

resource "aws_route_table_association" "shoora_private" {
  count = var.private_subnet_enabled ? length(aws_subnet.shoora_private.*.id) : 0

  subnet_id      = element(aws_subnet.shoora_private.*.id, count.index)
  route_table_id = aws_route_table.shoora_private[0].id
}
