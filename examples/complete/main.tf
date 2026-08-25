terraform {
  required_version = ">= 1.5.0"

  required_providers {
    scaleway = {
      source  = "scaleway/scaleway"
      version = ">= 2.81, < 3.0"
    }
  }
}

provider "scaleway" {
  region = "fr-par"
  zone   = "fr-par-1"
}

module "vpc" {
  source = "../../"

  name           = "example"
  region         = "fr-par"
  enable_routing = true

  private_networks = {
    main = {
      subnet = "10.10.0.0/20"
    }
    data = {
      subnet = "10.10.16.0/22"
      tags   = { purpose = "databases" }
    }
    auto = {}
  }

  tags = {
    environment = "example"
    managed-by  = "opentofu"
  }
}

output "private_network_ids" {
  value = module.vpc.private_network_ids
}
