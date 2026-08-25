locals {
  enabled = var.create

  tags = [for k, v in var.tags : "${k}=${v}"]

  vpc_id = var.create_vpc ? one(scaleway_vpc.this[*].id) : var.vpc_id

  private_networks = local.enabled ? var.private_networks : {}
}

resource "scaleway_vpc" "this" {
  count = local.enabled && var.create_vpc ? 1 : 0

  name                             = var.name
  region                           = var.region
  project_id                       = var.project_id
  enable_routing                   = var.enable_routing
  enable_custom_routes_propagation = var.enable_custom_routes_propagation
  enable_transitivity              = var.enable_transitivity
  tags                             = local.tags
}

resource "scaleway_vpc_private_network" "this" {
  for_each = local.private_networks

  name                             = coalesce(each.value.name, var.name == null ? each.key : "${var.name}-${each.key}")
  vpc_id                           = local.vpc_id
  region                           = var.region
  project_id                       = var.project_id
  enable_default_route_propagation = each.value.enable_default_route_propagation

  tags = concat(
    local.tags,
    [for k, v in each.value.tags : "${k}=${v}"],
  )

  dynamic "ipv4_subnet" {
    for_each = each.value.subnet == null ? [] : [each.value.subnet]
    content {
      subnet = ipv4_subnet.value
    }
  }

  dynamic "ipv6_subnets" {
    for_each = each.value.subnet_v6 == null ? [] : [each.value.subnet_v6]
    content {
      subnet = ipv6_subnets.value
    }
  }

  lifecycle {
    precondition {
      condition     = var.create_vpc || var.vpc_id != null
      error_message = "Set `vpc_id` when `create_vpc` is false, otherwise there is no VPC to attach private networks to."
    }
  }
}
