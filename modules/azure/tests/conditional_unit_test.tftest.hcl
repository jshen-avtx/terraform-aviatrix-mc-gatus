# Unit tests covering conditional resource creation paths driven by the
# `dashboard` and `dashboard_ssh_key` variables. All runs use command = plan
# with mocked providers so nothing real is created.

mock_provider "azurerm" {}

mock_provider "cloudinit" {
  mock_data "cloudinit_config" {
    defaults = {
      rendered = "IyEvYmluL2Jhc2g="
    }
  }
}

mock_provider "http" {
  mock_data "http" {
    defaults = {
      response_body = "203.0.113.1"
    }
  }
}

mock_provider "random" {
  mock_resource "random_password" {
    defaults = {
      result = "MockPass123!"
    }
  }
}

mock_provider "terracurl" {
  mock_resource "terracurl_request" {
    defaults = {
      id          = "dashboard"
      response    = "{}"
      status_code = 200
    }
  }
}

# Dashboard enabled: dashboard VM, its NSG, HTTP(S) ingress, and cloud-init data all created.
run "test_dashboard_created_when_enabled" {
  command = plan
  variables {
    azure_region          = "eastus"
    dashboard             = true
    dashboard_access_cidr = "203.0.113.0/24"
  }
  assert {
    condition     = length(module.dashboard) == 1
    error_message = "Expected module.dashboard count 1 when dashboard enabled, got ${length(module.dashboard)}."
  }
  assert {
    condition     = length(azurerm_network_security_group.this_dashboard) == 1
    error_message = "Expected azurerm_network_security_group.this_dashboard count 1 when dashboard enabled, got ${length(azurerm_network_security_group.this_dashboard)}."
  }
  assert {
    condition     = length(azurerm_network_security_rule.this_inbound_dashboard) == 1
    error_message = "Expected azurerm_network_security_rule.this_inbound_dashboard count 1 when dashboard enabled, got ${length(azurerm_network_security_rule.this_inbound_dashboard)}."
  }
  assert {
    condition     = length(data.cloudinit_config.dashboard) == 1
    error_message = "Expected data.cloudinit_config.dashboard count 1 when dashboard enabled, got ${length(data.cloudinit_config.dashboard)}."
  }
}

# Dashboard disabled — all dashboard-scoped resources should have count 0.
run "test_dashboard_not_created_when_disabled" {
  command = plan
  variables {
    azure_region = "eastus"
    dashboard    = false
  }
  assert {
    condition     = length(module.dashboard) == 0
    error_message = "Expected module.dashboard count 0 when dashboard disabled, got ${length(module.dashboard)}."
  }
  assert {
    condition     = length(azurerm_network_security_group.this_dashboard) == 0
    error_message = "Expected azurerm_network_security_group.this_dashboard count 0 when dashboard disabled, got ${length(azurerm_network_security_group.this_dashboard)}."
  }
  assert {
    condition     = length(azurerm_network_security_rule.this_inbound_dashboard) == 0
    error_message = "Expected azurerm_network_security_rule.this_inbound_dashboard count 0 when dashboard disabled, got ${length(azurerm_network_security_rule.this_inbound_dashboard)}."
  }
  assert {
    condition     = length(data.cloudinit_config.dashboard) == 0
    error_message = "Expected data.cloudinit_config.dashboard count 0 when dashboard disabled, got ${length(data.cloudinit_config.dashboard)}."
  }
}

# Dashboard enabled WITH SSH key: SSH ingress rule is also created.
run "test_ssh_rule_created_when_key_provided" {
  command = plan
  variables {
    azure_region          = "eastus"
    dashboard             = true
    dashboard_ssh_key     = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQ test@example"
    dashboard_access_cidr = "203.0.113.0/24"
  }
  assert {
    condition     = length(azurerm_network_security_rule.this_inbound_ssh) == 1
    error_message = "Expected azurerm_network_security_rule.this_inbound_ssh count 1 when ssh key provided, got ${length(azurerm_network_security_rule.this_inbound_ssh)}."
  }
}

# Dashboard enabled but no SSH key: no SSH ingress rule.
run "test_ssh_rule_not_created_without_key" {
  command = plan
  variables {
    azure_region          = "eastus"
    dashboard             = true
    dashboard_ssh_key     = null
    dashboard_access_cidr = "203.0.113.0/24"
  }
  assert {
    condition     = length(azurerm_network_security_rule.this_inbound_ssh) == 0
    error_message = "Expected azurerm_network_security_rule.this_inbound_ssh count 0 when ssh key absent, got ${length(azurerm_network_security_rule.this_inbound_ssh)}."
  }
}

# When dashboard=false, azure_dashboard_public_ip output should be null.
run "test_output_null_when_no_dashboard" {
  command = plan
  variables {
    azure_region = "eastus"
    dashboard    = false
  }
  assert {
    condition     = output.azure_dashboard_public_ip == null
    error_message = "Expected output.azure_dashboard_public_ip to be null when dashboard is disabled."
  }
}
