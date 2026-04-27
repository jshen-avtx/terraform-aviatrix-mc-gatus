# Unit tests covering default variable behavior and resource counts using
# mock_provider. All runs use command = plan so no real cloud calls happen.

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

# Default number_of_instances is 2; two gatus VMs should be planned.
run "test_default_instance_count" {
  command = plan
  variables {
    azure_region          = "eastus"
    dashboard_access_cidr = "203.0.113.0/24"
  }
  assert {
    condition     = length(module.gatus) == 2
    error_message = "Expected 2 gatus instances by default but got ${length(module.gatus)}."
  }
}

# When local_user_password is null, random_password is created (count 1).
run "test_password_generated_when_not_provided" {
  command = plan
  variables {
    azure_region          = "eastus"
    local_user_password   = null
    dashboard_access_cidr = "203.0.113.0/24"
  }
  assert {
    condition     = length(random_password.password) == 1
    error_message = "Expected random_password.password count 1 when password not provided, got ${length(random_password.password)}."
  }
}

# When a password is provided, random_password is skipped.
run "test_password_not_generated_when_provided" {
  command = plan
  variables {
    azure_region          = "eastus"
    local_user_password   = "mypassword"
    dashboard_access_cidr = "203.0.113.0/24"
  }
  assert {
    condition     = length(random_password.password) == 0
    error_message = "Expected random_password.password count 0 when password provided, got ${length(random_password.password)}."
  }
}

run "test_single_instance" {
  command = plan
  variables {
    azure_region          = "eastus"
    number_of_instances   = 1
    dashboard_access_cidr = "203.0.113.0/24"
  }
  assert {
    condition     = length(module.gatus) == 1
    error_message = "Expected 1 gatus instance, got ${length(module.gatus)}."
  }
}

run "test_three_instances" {
  command = plan
  variables {
    azure_region          = "eastus"
    number_of_instances   = 3
    dashboard_access_cidr = "203.0.113.0/24"
  }
  assert {
    condition     = length(module.gatus) == 3
    error_message = "Expected 3 gatus instances, got ${length(module.gatus)}."
  }
}
