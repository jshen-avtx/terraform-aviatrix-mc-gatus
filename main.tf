data "aws_regions" "available" {}

module "aws" {
  for_each                  = contains([for s in var.clouds : lower(s)], "aws") ? toset(["aws"]) : toset([])
  source                    = "./modules/aws"
  aws_cidr                  = var.aws_cidr
  aws_region                = var.aws_region
  aws_instance_type         = var.aws_instance_type
  dashboard                 = var.dashboard || var.dashboard_ssh_key != null
  dashboard_access_cidr     = var.dashboard_access_cidr
  dashboard_user            = var.dashboard_user
  dashboard_password        = var.dashboard_password
  dashboard_certificate     = var.dashboard_certificate
  dashboard_certificate_key = var.dashboard_certificate_key
  dashboard_ssh_key         = var.dashboard_ssh_key
  gatus_endpoints           = var.gatus_endpoints
  gatus_interval            = var.gatus_interval
  gatus_version             = var.gatus_version
  local_user                = var.local_user
  local_user_password       = var.local_user_password
  name_prefix               = var.name_prefix
  number_of_instances       = var.number_of_instances
}

module "azure" {
  for_each                  = contains([for s in var.clouds : lower(s)], "azure") ? toset(["azure"]) : toset([])
  source                    = "./modules/azure"
  azure_cidr                = var.azure_cidr
  azure_region              = var.azure_region == null ? "region_placeholder" : var.azure_region
  azure_instance_type       = var.azure_instance_type
  dashboard                 = var.dashboard || var.dashboard_ssh_key != null
  dashboard_access_cidr     = var.dashboard_access_cidr
  dashboard_user            = var.dashboard_user
  dashboard_password        = var.dashboard_password
  dashboard_certificate     = var.dashboard_certificate
  dashboard_certificate_key = var.dashboard_certificate_key
  dashboard_ssh_key         = var.dashboard_ssh_key
  gatus_endpoints           = var.gatus_endpoints
  gatus_interval            = var.gatus_interval
  gatus_version             = var.gatus_version
  local_user                = var.local_user
  local_user_password       = var.local_user_password
  name_prefix               = var.name_prefix
  number_of_instances       = var.number_of_instances
}
