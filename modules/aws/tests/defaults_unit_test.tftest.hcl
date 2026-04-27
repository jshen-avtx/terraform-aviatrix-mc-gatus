# Unit tests covering default variable behavior and resource counts using
# mock_provider. All runs use command = plan so no real cloud calls happen.

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

# Default number_of_instances is 2; gatus module is keyed by toset, so two entries.
run "test_default_instance_count" {
  command = plan
  variables {
    aws_region = "us-east-1"
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
    aws_region          = "us-east-1"
    local_user_password = null
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
    aws_region          = "us-east-1"
    local_user_password = "mypassword"
  }
  assert {
    condition     = length(random_password.password) == 0
    error_message = "Expected random_password.password count 0 when password provided, got ${length(random_password.password)}."
  }
}

# name_prefix is composed into security group names as "${name_prefix}-".
run "test_name_prefix_applied" {
  command = plan
  variables {
    aws_region  = "us-east-1"
    name_prefix = "test"
  }
  assert {
    condition     = can(regex("^test-", aws_security_group.this.name))
    error_message = "Expected aws_security_group.this.name to start with 'test-', got '${aws_security_group.this.name}'."
  }
}

run "test_single_instance" {
  command = plan
  variables {
    aws_region          = "us-east-1"
    number_of_instances = 1
  }
  assert {
    condition     = length(module.gatus) == 1
    error_message = "Expected 1 gatus instance, got ${length(module.gatus)}."
  }
}

run "test_three_instances" {
  command = plan
  variables {
    aws_region          = "us-east-1"
    number_of_instances = 3
  }
  assert {
    condition     = length(module.gatus) == 3
    error_message = "Expected 3 gatus instances, got ${length(module.gatus)}."
  }
}
