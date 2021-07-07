resource "aws_lb" "xtages_console_lb" {
  name               = "xtages-console-lb-${var.env}"
  internal           = false
  load_balancer_type = "application"
  enable_http2       = true

  security_groups = [aws_security_group.xtages_lb_sg.id]
  subnets         = var.public_subnet_ids

  tags = local.tags
}

resource "aws_lb" "xtages_customers_lb" {
  name               = "xtages-customers-lb-${var.env}"
  internal           = false
  load_balancer_type = "application"
  enable_http2       = true

  security_groups = [aws_security_group.xtages_lb_sg.id]
  subnets         = var.public_subnet_ids

  tags = local.tags
}
