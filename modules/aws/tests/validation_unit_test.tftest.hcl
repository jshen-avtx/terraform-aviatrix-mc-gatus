# Unit tests for variable validation rules in the AWS submodule.
# Each negative run uses expect_failures to confirm a validation rejects bad input;
# each positive run confirms a valid value is accepted at plan time.

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

# ------------------------------------------------------------------
# aws_region validation: must match ^[a-z]+-[a-z]+-[0-9]+$
# ------------------------------------------------------------------

run "aws_region_rejects_plain_word" {
  command = plan
  variables {
    aws_region = "invalid"
  }
  expect_failures = [var.aws_region]
}

run "aws_region_rejects_underscores" {
  command = plan
  variables {
    aws_region = "us_east_1"
  }
  expect_failures = [var.aws_region]
}

run "aws_region_rejects_uppercase" {
  command = plan
  variables {
    aws_region = "US-EAST-1"
  }
  expect_failures = [var.aws_region]
}

run "aws_region_accepts_valid_region" {
  command = plan
  variables {
    aws_region = "us-east-1"
  }
}

# ------------------------------------------------------------------
# aws_cidr validation: must be valid IPv4 CIDR
# ------------------------------------------------------------------

run "aws_cidr_rejects_non_cidr" {
  command = plan
  variables {
    aws_region = "us-east-1"
    aws_cidr   = "not-a-cidr"
  }
  expect_failures = [var.aws_cidr]
}

run "aws_cidr_rejects_invalid_octets" {
  command = plan
  variables {
    aws_region = "us-east-1"
    aws_cidr   = "999.999.0.0/24"
  }
  expect_failures = [var.aws_cidr]
}

run "aws_cidr_accepts_valid_cidr" {
  command = plan
  variables {
    aws_region = "us-east-1"
    aws_cidr   = "10.1.0.0/24"
  }
}

# ------------------------------------------------------------------
# number_of_instances validation: must be 1..3
# ------------------------------------------------------------------

run "number_of_instances_rejects_zero" {
  command = plan
  variables {
    aws_region          = "us-east-1"
    number_of_instances = 0
  }
  expect_failures = [var.number_of_instances]
}

run "number_of_instances_rejects_four" {
  command = plan
  variables {
    aws_region          = "us-east-1"
    number_of_instances = 4
  }
  expect_failures = [var.number_of_instances]
}

run "number_of_instances_accepts_two" {
  command = plan
  variables {
    aws_region          = "us-east-1"
    number_of_instances = 2
  }
}

# ------------------------------------------------------------------
# dashboard_access_cidr validation: null OK, otherwise valid CIDR
# ------------------------------------------------------------------

run "dashboard_access_cidr_rejects_non_cidr" {
  command = plan
  variables {
    aws_region            = "us-east-1"
    dashboard_access_cidr = "not-a-cidr"
  }
  expect_failures = [var.dashboard_access_cidr]
}

run "dashboard_access_cidr_accepts_valid_cidr" {
  command = plan
  variables {
    aws_region            = "us-east-1"
    dashboard_access_cidr = "203.0.113.0/24"
  }
}

run "dashboard_access_cidr_accepts_null" {
  command = plan
  variables {
    aws_region            = "us-east-1"
    dashboard_access_cidr = null
  }
}

# ------------------------------------------------------------------
# name_prefix validation: <=33 chars, lowercase letters/numbers/hyphens only
# ------------------------------------------------------------------

run "name_prefix_rejects_too_long" {
  command = plan
  variables {
    aws_region  = "us-east-1"
    name_prefix = "this-name-prefix-is-definitely-way-too-long-for-validation"
  }
  expect_failures = [var.name_prefix]
}

run "name_prefix_rejects_uppercase" {
  command = plan
  variables {
    aws_region  = "us-east-1"
    name_prefix = "BadPrefix"
  }
  expect_failures = [var.name_prefix]
}

run "name_prefix_rejects_spaces" {
  command = plan
  variables {
    aws_region  = "us-east-1"
    name_prefix = "bad prefix"
  }
  expect_failures = [var.name_prefix]
}

run "name_prefix_accepts_valid" {
  command = plan
  variables {
    aws_region  = "us-east-1"
    name_prefix = "mc-gatus"
  }
}
