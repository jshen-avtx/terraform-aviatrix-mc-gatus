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

resource "azurerm_resource_group" "this" {
  name     = "${local.name_prefix}rg"
  location = var.azure_region
}

resource "azurerm_nat_gateway" "this" {
  location            = azurerm_resource_group.this.location
  name                = "${local.name_prefix}nat"
  resource_group_name = azurerm_resource_group.this.name
}

resource "azurerm_public_ip" "nat" {
  name                = "${local.name_prefix}nat-ip"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_nat_gateway_public_ip_association" "nat" {
  nat_gateway_id       = azurerm_nat_gateway.this.id
  public_ip_address_id = azurerm_public_ip.nat.id
}

resource "azurerm_route_table" "public" {
  location            = azurerm_resource_group.this.location
  name                = "${local.name_prefix}public-rt"
  resource_group_name = azurerm_resource_group.this.name
}

resource "azurerm_route_table" "private" {
  location            = azurerm_resource_group.this.location
  name                = "${local.name_prefix}private-rt"
  resource_group_name = azurerm_resource_group.this.name
}

module "vnet" {
  source  = "Azure/avm-res-network-virtualnetwork/azurerm"
  version = "0.8.1"

  address_space       = [var.azure_cidr]
  location            = azurerm_resource_group.this.location
  name                = "${local.name_prefix}vnet"
  resource_group_name = azurerm_resource_group.this.name
}

resource "azurerm_subnet" "public" {
  count                           = var.number_of_instances
  name                            = "${local.name_prefix}-public-subnet${count.index + 1}"
  resource_group_name             = azurerm_resource_group.this.name
  virtual_network_name            = module.vnet.name
  address_prefixes                = [local.public_subnets[count.index]]
  default_outbound_access_enabled = true
}

resource "azurerm_subnet" "public_gateway" {
  name                            = "${local.name_prefix}-public-gateway-subnet"
  resource_group_name             = azurerm_resource_group.this.name
  virtual_network_name            = module.vnet.name
  address_prefixes                = [cidrsubnet(var.azure_cidr, 4, 6)]
  default_outbound_access_enabled = true
}

resource "azurerm_subnet_route_table_association" "public" {
  count          = var.number_of_instances
  subnet_id      = azurerm_subnet.public[count.index].id
  route_table_id = azurerm_route_table.public.id
}

resource "azurerm_subnet" "private" {
  count                           = var.number_of_instances
  name                            = "${local.name_prefix}private-subnet-${count.index + 1}"
  resource_group_name             = azurerm_resource_group.this.name
  virtual_network_name            = module.vnet.name
  address_prefixes                = [local.private_subnets[count.index]]
  default_outbound_access_enabled = false
}

resource "azurerm_subnet_route_table_association" "private" {
  count          = var.number_of_instances
  subnet_id      = azurerm_subnet.private[count.index].id
  route_table_id = azurerm_route_table.private.id
}

resource "azurerm_subnet_nat_gateway_association" "this" {
  count          = var.number_of_instances
  subnet_id      = azurerm_subnet.private[count.index].id
  nat_gateway_id = azurerm_nat_gateway.this.id
}

data "cloudinit_config" "gatus" {
  count         = var.number_of_instances
  gzip          = false
  base64_encode = true

  part {
    content_type = "text/x-shellscript"
    content = templatefile("${path.module}/templates/gatus.tpl",
      {
        name     = "${local.name_prefix}azure-gatus-az${count.index + 1}"
        user     = var.local_user
        password = var.local_user_password != null ? var.local_user_password : random_password.password[0].result
        https    = var.gatus_endpoints.https
        http     = var.gatus_endpoints.http
        tcp      = var.gatus_endpoints.tcp
        icmp     = var.gatus_endpoints.icmp
        interval = var.gatus_interval
        version  = var.gatus_version
    })
  }
}

module "gatus" {
  count               = var.number_of_instances
  source              = "Azure/avm-res-compute-virtualmachine/azurerm"
  version             = "0.18.0"
  resource_group_name = azurerm_resource_group.this.name
  location            = azurerm_resource_group.this.location
  name                = "${local.name_prefix}azure-gatus-az${count.index + 1}"
  admin_username      = var.local_user
  admin_password      = var.local_user_password != null ? var.local_user_password : random_password.password[0].result
  user_data           = data.cloudinit_config.gatus[count.index].rendered
  sku_size            = var.azure_instance_type
  os_type             = "Linux"
  os_disk = {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }
  source_image_reference = {
    publisher = "Canonical"
    offer     = "ubuntu-24_04-lts"
    sku       = "server"
    version   = "latest"
  }
  encryption_at_host_enabled = false
  zone                       = count.index + 1
  network_interfaces = {
    network_interface_1 = {
      name = "${local.name_prefix}azure-gatus-az${count.index + 1}-nic"
      ip_configurations = {
        ip_configuration_1 = {
          name                          = "${local.name_prefix}azure-gatus-az${count.index + 1}-ipconfig1"
          private_ip_subnet_resource_id = azurerm_subnet.private[count.index].id
        }
      }
    }
  }
}

data "cloudinit_config" "dashboard" {
  count         = var.dashboard ? 1 : 0
  gzip          = false
  base64_encode = true

  part {
    content_type = "text/x-shellscript"
    content = templatefile("${path.module}/templates/dashboard.tpl",
      {
        cloud     = "azure"
        instances = [for instance in module.gatus : instance.virtual_machine_azurerm.private_ip_addresses[0]]
        version   = var.gatus_version
        user      = var.dashboard_user != null ? var.dashboard_user : "placeholder"
        password  = var.dashboard_password != null ? var.dashboard_password : "placeholder"
        cert      = var.dashboard_password != null ? var.dashboard_certificate : "placeholder"
        key       = var.dashboard_password != null ? var.dashboard_certificate_key : "placeholder"
    })
  }
}

module "dashboard" {
  count               = var.dashboard ? 1 : 0
  source              = "Azure/avm-res-compute-virtualmachine/azurerm"
  version             = "0.18.0"
  resource_group_name = azurerm_resource_group.this.name
  location            = azurerm_resource_group.this.location
  name                = "${local.name_prefix}azure-gatus-dashboard"
  admin_username      = var.local_user
  admin_password      = var.local_user_password != null ? var.local_user_password : random_password.password[0].result
  user_data           = data.cloudinit_config.dashboard[0].rendered
  sku_size            = var.azure_instance_type
  os_type             = "Linux"
  os_disk = {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }
  source_image_reference = {
    publisher = "Canonical"
    offer     = "ubuntu-24_04-lts"
    sku       = "server"
    version   = "latest"
  }
  encryption_at_host_enabled = false
  zone                       = 1
  # # Waiting for the fix on 0.19.1 to allow custom ssh key
  # #  on .terraform/modules/mc_gatus.dashboard/modules/run-command/main.tf line 50, in resource "azurerm_virtual_machine_run_command" "this":
  # # │   50:     for_each = try(length(var.protected_parameters) > 0, false) ? var.protected_parameters : []
  # # │ 
  # # │ Cannot use a list of object value in for_each. An iterable collection is required.
  # account_credentials = {
  #   admin_credentials = {
  #     username                           = var.local_user
  #     generate_admin_password_or_ssh_key = false
  #     password_authentication_disabled   = true
  #     ssh_keys                           = [var.dashboard_ssh_key]
  #   }
  # }
  network_interfaces = {

    network_interface_1 = {
      name = "${local.name_prefix}azure-gatus-dashboard-nic"
      ip_configurations = {
        ip_configuration_1 = {
          name                          = "${local.name_prefix}azure-gatus-dashboard-ipconfig1"
          private_ip_subnet_resource_id = azurerm_subnet.public[0].id
          create_public_ip_address      = true
          public_ip_address_name        = "${local.name_prefix}azure-gatus-dashboard-pip"
        }
      }
    }
  }
}

resource "terracurl_request" "dashboard" {
  count           = var.dashboard ? 1 : 0
  name            = "dashboard"
  url             = var.dashboard_password == null ? "http://${module.dashboard[0].public_ips.network_interface_1-ip_configuration_1.ip_address}" : "https://${module.dashboard[0].public_ips.network_interface_1-ip_configuration_1.ip_address}"
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

resource "azurerm_network_security_group" "this" {
  name                = "${local.name_prefix}sg"
  resource_group_name = azurerm_resource_group.this.name
  location            = azurerm_resource_group.this.location
}

resource "azurerm_network_security_group" "this_dashboard" {
  count               = var.dashboard ? 1 : 0
  name                = "${local.name_prefix}dashboard-sg"
  resource_group_name = azurerm_resource_group.this.name
  location            = azurerm_resource_group.this.location
}

resource "azurerm_network_interface_security_group_association" "this_gatus" {
  count                     = var.number_of_instances
  network_interface_id      = module.gatus[count.index].network_interfaces.network_interface_1.id
  network_security_group_id = azurerm_network_security_group.this.id
}

resource "azurerm_network_interface_security_group_association" "this_dashboard" {
  count                     = var.dashboard ? 1 : 0
  network_interface_id      = module.dashboard[0].network_interfaces.network_interface_1.id
  network_security_group_id = azurerm_network_security_group.this_dashboard[0].id
}

resource "azurerm_network_security_rule" "this_rfc_1918" {
  access                      = "Allow"
  direction                   = "Inbound"
  name                        = "rfc-1918"
  priority                    = 100
  protocol                    = "*"
  source_port_range           = "*"
  source_address_prefixes     = ["10.0.0.0/8", "172.16.0.0/12", "192.168.0.0/16"]
  destination_port_range      = "*"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.this.name
  network_security_group_name = azurerm_network_security_group.this.name
}

resource "azurerm_network_security_rule" "this_inbound_dashboard" {
  count                       = var.dashboard ? 1 : 0
  access                      = "Allow"
  direction                   = "Inbound"
  name                        = "dashboard_inbound_tcp"
  priority                    = 101
  protocol                    = "Tcp"
  source_port_range           = "*"
  source_address_prefixes     = var.dashboard_access_cidr != null ? [var.dashboard_access_cidr] : ["${chomp(data.http.my_ip.response_body)}/32"]
  destination_port_range      = var.dashboard_password != null ? "443" : "80"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.this.name
  network_security_group_name = azurerm_network_security_group.this_dashboard[0].name
}

resource "azurerm_network_security_rule" "this_inbound_ssh" {
  count                       = var.dashboard && var.dashboard_ssh_key != null ? 1 : 0
  access                      = "Allow"
  direction                   = "Inbound"
  name                        = "dashboard_inbound_ssh"
  priority                    = 102
  protocol                    = "Tcp"
  source_port_range           = "*"
  source_address_prefixes     = var.dashboard_access_cidr != null ? [var.dashboard_access_cidr] : ["${chomp(data.http.my_ip.response_body)}/32"]
  destination_port_range      = 22
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.this.name
  network_security_group_name = azurerm_network_security_group.this_dashboard[0].name
}
