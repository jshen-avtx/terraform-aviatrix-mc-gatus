locals {
  az_suffixes     = ["a", "b", "c"]
  azs             = [for i in range(var.number_of_instances) : "${var.aws_region}${local.az_suffixes[i % length(local.az_suffixes)]}"]
  subnets         = cidrsubnets(var.aws_cidr, [for i in range(var.number_of_instances * 2) : "4"]...)
  private_subnets = slice(local.subnets, 0, var.number_of_instances)
  public_subnets  = slice(local.subnets, var.number_of_instances, var.number_of_instances * 2)
  name_prefix     = "${var.name_prefix}-"
}
