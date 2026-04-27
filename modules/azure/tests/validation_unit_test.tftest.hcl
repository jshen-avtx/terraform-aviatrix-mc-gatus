# Unit tests for variable validation rules in the Azure submodule.
# Each negative run uses expect_failures to confirm a validation rejects bad input;
# each positive run confirms a valid value is accepted at plan time.

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

# ------------------------------------------------------------------
# azure_region validation: must be in the allowed-regions list
# ------------------------------------------------------------------

run "azure_region_rejects_invalid" {
  command = plan
  variables {
    azure_region = "invalid-region"
  }
  expect_failures = [var.azure_region]
}

run "azure_region_rejects_aws_style_region" {
  command = plan
  variables {
    azure_region = "us-east-1"
  }
  expect_failures = [var.azure_region]
}

run "azure_region_accepts_eastus" {
  command = plan
  variables {
    azure_region          = "eastus"
    dashboard_access_cidr = "203.0.113.0/24"
  }
}

run "azure_region_accepts_westeurope" {
  command = plan
  variables {
    azure_region          = "westeurope"
    dashboard_access_cidr = "203.0.113.0/24"
  }
}

# ------------------------------------------------------------------
# azure_cidr validation: must be a valid IPv4 CIDR
# ------------------------------------------------------------------

run "azure_cidr_rejects_non_cidr" {
  command = plan
  variables {
    azure_region = "eastus"
    azure_cidr   = "not-a-cidr"
  }
  expect_failures = [var.azure_cidr]
}

run "azure_cidr_rejects_invalid_octets" {
  command = plan
  variables {
    azure_region = "eastus"
    azure_cidr   = "999.999.0.0/24"
  }
  expect_failures = [var.azure_cidr]
}

run "azure_cidr_accepts_valid_cidr" {
  command = plan
  variables {
    azure_region          = "eastus"
    azure_cidr            = "10.2.0.0/24"
    dashboard_access_cidr = "203.0.113.0/24"
  }
}

# ------------------------------------------------------------------
# number_of_instances validation: must be 1..3
# ------------------------------------------------------------------

run "number_of_instances_rejects_zero" {
  command = plan
  variables {
    azure_region        = "eastus"
    number_of_instances = 0
  }
  expect_failures = [var.number_of_instances]
}

run "number_of_instances_rejects_four" {
  command = plan
  variables {
    azure_region        = "eastus"
    number_of_instances = 4
  }
  expect_failures = [var.number_of_instances]
}

run "number_of_instances_accepts_two" {
  command = plan
  variables {
    azure_region          = "eastus"
    number_of_instances   = 2
    dashboard_access_cidr = "203.0.113.0/24"
  }
}

# ------------------------------------------------------------------
# dashboard_access_cidr validation: null OK, otherwise valid CIDR
# ------------------------------------------------------------------

run "dashboard_access_cidr_rejects_non_cidr" {
  command = plan
  variables {
    azure_region          = "eastus"
    dashboard_access_cidr = "not-a-cidr"
  }
  expect_failures = [var.dashboard_access_cidr]
}

run "dashboard_access_cidr_accepts_valid_cidr" {
  command = plan
  variables {
    azure_region          = "eastus"
    dashboard_access_cidr = "203.0.113.0/24"
  }
}

run "dashboard_access_cidr_accepts_null" {
  command = plan
  variables {
    azure_region          = "eastus"
    dashboard_access_cidr = null
  }
}

# ------------------------------------------------------------------
# name_prefix validation: <=33 chars, lowercase letters/numbers/hyphens only
# ------------------------------------------------------------------

run "name_prefix_rejects_too_long" {
  command = plan
  variables {
    azure_region = "eastus"
    name_prefix  = "this-name-prefix-is-definitely-way-too-long-for-validation"
  }
  expect_failures = [var.name_prefix]
}

run "name_prefix_rejects_uppercase" {
  command = plan
  variables {
    azure_region = "eastus"
    name_prefix  = "BadPrefix"
  }
  expect_failures = [var.name_prefix]
}

run "name_prefix_rejects_spaces" {
  command = plan
  variables {
    azure_region = "eastus"
    name_prefix  = "bad prefix"
  }
  expect_failures = [var.name_prefix]
}

run "name_prefix_accepts_valid" {
  command = plan
  variables {
    azure_region          = "eastus"
    name_prefix           = "mc-gatus"
    dashboard_access_cidr = "203.0.113.0/24"
  }
}
