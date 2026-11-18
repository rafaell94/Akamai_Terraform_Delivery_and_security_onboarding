terraform {
  required_version = ">= 1.9.0"
  required_providers {
    akamai = {
      source  = "akamai/akamai"
      version = "~> 12.0"
    }
    time = {
      source  = "hashicorp/time"
      version = "~> 0.13"
    }
  }
}
