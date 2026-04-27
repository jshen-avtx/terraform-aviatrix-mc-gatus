# Unit tests covering conditional resource creation paths driven by the
# `dashboard` and `dashboard_ssh_key` variables. All runs use command = plan
# with mocked providers so nothing real is created.

mock_provider "aws" {
  mock_data "aws_regions" {
    defaults = {
      names = ["us-east-1", "us-west-2", "eu-west-1"]
    }
  }
  mock_data "aws_ssm_parameter" {
    defaults = {
      value = "ami-0abcdef1234567890"
    }
  }
  mock_resource "aws_security_group" {
    defaults = {
      id  = "sg-12345678"
      arn = "arn:aws:ec2:us-east-1:123456789012:security-group/sg-12345678"
    }
  }
  mock_resource "aws_security_group_rule" {
    defaults = {
      id = "sgr-12345678"
    }
  }
  mock_resource "aws_key_pair" {
    defaults = {
      id          = "kp-12345678"
      key_pair_id = "key-12345678"
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
  mock_resource "random_id" {
    defaults = {
      id      = "abcd1234"
      hex     = "abcd1234"
      b64_url = "abcd1234"
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

# Dashboard enabled: dashboard module + dashboard SG + ingress + egress all created.
run "test_dashboard_created_when_enabled" {
  command = plan
  variables {
    aws_region = "us-east-1"
    dashboard  = true
  }
  assert {
    condition     = length(module.dashboard) == 1
    error_message = "Expected module.dashboard count 1 when dashboard enabled, got ${length(module.dashboard)}."
  }
  assert {
    condition     = length(aws_security_group.this_dashboard) == 1
    error_message = "Expected aws_security_group.this_dashboard count 1 when dashboard enabled, got ${length(aws_security_group.this_dashboard)}."
  }
  assert {
    condition     = length(aws_security_group_rule.this_dashboard) == 1
    error_message = "Expected aws_security_group_rule.this_dashboard count 1 when dashboard enabled, got ${length(aws_security_group_rule.this_dashboard)}."
  }
  assert {
    condition     = length(aws_security_group_rule.this_dashboard_egress) == 1
    error_message = "Expected aws_security_group_rule.this_dashboard_egress count 1 when dashboard enabled, got ${length(aws_security_group_rule.this_dashboard_egress)}."
  }
}

# Dashboard disabled (and no SSH key) — no dashboard resources are created.
run "test_dashboard_not_created_when_disabled" {
  command = plan
  variables {
    aws_region        = "us-east-1"
    dashboard         = false
    dashboard_ssh_key = null
  }
  assert {
    condition     = length(module.dashboard) == 0
    error_message = "Expected module.dashboard count 0 when dashboard disabled, got ${length(module.dashboard)}."
  }
  assert {
    condition     = length(aws_security_group.this_dashboard) == 0
    error_message = "Expected aws_security_group.this_dashboard count 0 when dashboard disabled, got ${length(aws_security_group.this_dashboard)}."
  }
  assert {
    condition     = length(aws_security_group_rule.this_dashboard) == 0
    error_message = "Expected aws_security_group_rule.this_dashboard count 0 when dashboard disabled, got ${length(aws_security_group_rule.this_dashboard)}."
  }
  assert {
    condition     = length(aws_security_group_rule.this_dashboard_egress) == 0
    error_message = "Expected aws_security_group_rule.this_dashboard_egress count 0 when dashboard disabled, got ${length(aws_security_group_rule.this_dashboard_egress)}."
  }
}

# Dashboard enabled WITH SSH key: aws_key_pair and ssh ingress rule are created.
run "test_ssh_key_created_when_provided" {
  command = plan
  variables {
    aws_region        = "us-east-1"
    dashboard         = true
    dashboard_ssh_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQ test@example"
  }
  assert {
    condition     = length(aws_key_pair.dashboard_ssh_key) == 1
    error_message = "Expected aws_key_pair.dashboard_ssh_key count 1 when ssh key provided, got ${length(aws_key_pair.dashboard_ssh_key)}."
  }
  assert {
    condition     = length(aws_security_group_rule.this_dashboard_ssh) == 1
    error_message = "Expected aws_security_group_rule.this_dashboard_ssh count 1 when ssh key provided, got ${length(aws_security_group_rule.this_dashboard_ssh)}."
  }
}

# Dashboard enabled but no SSH key: no key_pair, no ssh ingress.
run "test_ssh_key_not_created_without_key" {
  command = plan
  variables {
    aws_region        = "us-east-1"
    dashboard         = true
    dashboard_ssh_key = null
  }
  assert {
    condition     = length(aws_key_pair.dashboard_ssh_key) == 0
    error_message = "Expected aws_key_pair.dashboard_ssh_key count 0 when ssh key absent, got ${length(aws_key_pair.dashboard_ssh_key)}."
  }
  assert {
    condition     = length(aws_security_group_rule.this_dashboard_ssh) == 0
    error_message = "Expected aws_security_group_rule.this_dashboard_ssh count 0 when ssh key absent, got ${length(aws_security_group_rule.this_dashboard_ssh)}."
  }
}

# Note: in the current module, var.dashboard alone gates dashboard creation.
# Providing dashboard_ssh_key while dashboard=false does NOT auto-enable the
# dashboard, but the key pair itself is still created (gated only on the key).
run "test_ssh_key_pair_independent_of_dashboard_flag" {
  command = plan
  variables {
    aws_region        = "us-east-1"
    dashboard         = false
    dashboard_ssh_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQ test@example"
  }
  assert {
    condition     = length(aws_key_pair.dashboard_ssh_key) == 1
    error_message = "Expected aws_key_pair.dashboard_ssh_key count 1 when ssh key provided regardless of dashboard flag, got ${length(aws_key_pair.dashboard_ssh_key)}."
  }
  assert {
    condition     = length(module.dashboard) == 0
    error_message = "Expected module.dashboard count 0 when dashboard=false even with ssh key, got ${length(module.dashboard)}."
  }
}

# When dashboard=false, the aws_dashboard_public_ip output should be null.
run "test_outputs_null_when_no_dashboard" {
  command = plan
  variables {
    aws_region = "us-east-1"
    dashboard  = false
  }
  assert {
    condition     = output.aws_dashboard_public_ip == null
    error_message = "Expected output.aws_dashboard_public_ip to be null when dashboard is disabled."
  }
}
