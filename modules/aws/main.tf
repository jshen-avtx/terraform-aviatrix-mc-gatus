data "aws_regions" "available" {}

data "http" "my_ip" {
  url = "https://ipv4.icanhazip.com"
}

resource "random_password" "password" {
  count            = var.local_user_password == null ? 1 : 0
  length           = 12
  special          = true
  override_special = "!#$%&*-_=+"
  min_lower        = 2
  min_upper        = 2
  min_numeric      = 2
  min_special      = 2
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.13.0"

  name = "${local.name_prefix}vpc"
  cidr = var.aws_cidr

  azs             = local.azs
  private_subnets = local.private_subnets
  public_subnets  = local.public_subnets

  enable_nat_gateway = true
  single_nat_gateway = true
  enable_vpn_gateway = false
}

resource "aws_security_group" "this" {
  name        = "${local.name_prefix}sg"
  description = "security group for aviatrix gatus instances"
  vpc_id      = module.vpc.vpc_id
}

resource "aws_security_group" "this_dashboard" {
  count       = var.dashboard ? 1 : 0
  name        = "${local.name_prefix}dashboard-sg"
  description = "security group for aviatrix dashboard instances"
  vpc_id      = module.vpc.vpc_id
}

resource "aws_security_group_rule" "this_ingress" {
  type              = "ingress"
  description       = "Allow inbound http access"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = ["10.0.0.0/8", "192.168.0.0/16", "172.16.0.0/12"]
  security_group_id = aws_security_group.this.id
}

resource "aws_security_group_rule" "this_dashboard" {
  count             = var.dashboard ? 1 : 0
  type              = "ingress"
  description       = "Allow inbound internet http access"
  from_port         = var.dashboard_password != null ? 443 : 80
  to_port           = var.dashboard_password != null ? 443 : 80
  protocol          = "tcp"
  cidr_blocks       = var.dashboard_access_cidr != null ? [var.dashboard_access_cidr] : ["${chomp(data.http.my_ip.response_body)}/32"]
  security_group_id = aws_security_group.this_dashboard[0].id
}

resource "aws_security_group_rule" "this_dashboard_ssh" {
  count             = var.dashboard && var.dashboard_ssh_key != null ? 1 : 0
  type              = "ingress"
  description       = "Allow inbound internet ssh access"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = ["${chomp(data.http.my_ip.response_body)}/32"]
  security_group_id = aws_security_group.this_dashboard[0].id
}

resource "aws_security_group_rule" "this_egress" {
  type              = "egress"
  description       = "Allow outbound access"
  from_port         = 0
  to_port           = 0
  protocol          = "all"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.this.id
}

resource "aws_security_group_rule" "this_dashboard_egress" {
  count             = var.dashboard ? 1 : 0
  type              = "egress"
  description       = "Allow outbound access"
  from_port         = 0
  to_port           = 0
  protocol          = "all"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.this_dashboard[0].id
}

data "aws_ssm_parameter" "ubuntu_ami" {
  name = "/aws/service/canonical/ubuntu/server/24.04/stable/current/amd64/hvm/ebs-gp3/ami-id"
}

module "gatus" {
  for_each = toset(formatlist("%d", range(var.number_of_instances)))
  source   = "terraform-aws-modules/ec2-instance/aws"
  version  = "6.4.0"

  name = "${local.name_prefix}aws-gatus-az${tonumber(each.value) + 1}"

  instance_type          = var.aws_instance_type
  vpc_security_group_ids = [aws_security_group.this.id]
  subnet_id              = element(module.vpc.private_subnets, each.key)
  ami                    = data.aws_ssm_parameter.ubuntu_ami.value

  user_data = templatefile("${path.module}/templates/gatus.tpl",
    {
      name     = "${local.name_prefix}aws-gatus-az${tonumber(each.value) + 1}"
      user     = var.local_user
      password = var.local_user_password != null ? var.local_user_password : random_password.password[0].result
      https    = var.gatus_endpoints.https
      http     = var.gatus_endpoints.http
      tcp      = var.gatus_endpoints.tcp
      icmp     = var.gatus_endpoints.icmp
      interval = var.gatus_interval
      version  = var.gatus_version
  })
  depends_on = [module.vpc]
}

resource "random_id" "this" {
  byte_length = 4
}

resource "aws_key_pair" "dashboard_ssh_key" {
  count      = var.dashboard_ssh_key == null ? 0 : 1
  key_name   = "dashboard-key-${module.vpc.vpc_id}-${random_id.this.id}"
  public_key = var.dashboard_ssh_key
}

module "dashboard" {
  count   = var.dashboard ? 1 : 0
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "6.4.0"

  name = "${local.name_prefix}aws-gatus-dashboard"

  instance_type               = var.aws_instance_type
  vpc_security_group_ids      = [aws_security_group.this_dashboard[0].id]
  subnet_id                   = module.vpc.public_subnets[0]
  ami                         = data.aws_ssm_parameter.ubuntu_ami.value
  associate_public_ip_address = true
  key_name                    = var.dashboard_ssh_key == null ? null : aws_key_pair.dashboard_ssh_key[0].key_name

  user_data = templatefile("${path.module}/templates/dashboard.tpl",
    {
      cloud     = "aws"
      instances = [for instance in module.gatus : instance.private_ip]
      version   = var.gatus_version
      user      = var.dashboard_user != null ? var.dashboard_user : "placeholder"
      password  = var.dashboard_password != null ? var.dashboard_password : "placeholder"
      cert      = var.dashboard_password != null ? var.dashboard_certificate : "placeholder"
      key       = var.dashboard_password != null ? var.dashboard_certificate_key : "placeholder"
  })
  depends_on = [module.gatus]
}

resource "terracurl_request" "dashboard" {
  count           = var.dashboard ? 1 : 0
  name            = "dashboard"
  url             = var.dashboard_password == null ? "http://${module.dashboard[0].public_ip}" : "https://${module.dashboard[0].public_ip}"
  method          = "GET"
  skip_tls_verify = var.dashboard_password == null ? null : true

  response_codes = [200]

  max_retry      = 30
  retry_interval = 10

  destroy_url    = "https://checkip.amazonaws.com"
  destroy_method = "GET"

  depends_on = [
    module.dashboard
  ]
}
