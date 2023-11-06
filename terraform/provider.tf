# AWS provider config
provider "aws" {
  region = "us-west-1"
}

terraform {
   required_providers {
    splunk = {
      source  = "splunk/splunk"
    }
  }
}

# Splunk provider config
provider "splunk" {
  url                  = "54.183.212.24:8089"
  username             = "admin"
  password             = SPLUNK-$instance id$
  insecure_skip_verify = true
}
