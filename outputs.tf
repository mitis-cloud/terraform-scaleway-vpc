output "vpc_id" {
  description = "Composite ID of the VPC, in `{region}/{uuid}` form. Reflects `var.vpc_id` when the module did not create one."
  value       = local.vpc_id
}

output "vpc_uuid" {
  description = "Bare UUID of the VPC, for the Scaleway APIs that reject the composite form."
  value       = local.vpc_id == null ? null : split("/", local.vpc_id)[1]
}

output "vpc_name" {
  description = "Name of the created VPC."
  value       = one(scaleway_vpc.this[*].name)
}

output "private_network_ids" {
  description = "Map of private network key to composite ID."
  value       = { for k, pn in scaleway_vpc_private_network.this : k => pn.id }
}

output "private_network_uuids" {
  description = "Map of private network key to bare UUID."
  value       = { for k, pn in scaleway_vpc_private_network.this : k => split("/", pn.id)[1] }
}

output "private_network_names" {
  description = "Map of private network key to resolved name."
  value       = { for k, pn in scaleway_vpc_private_network.this : k => pn.name }
}

output "private_network_subnets" {
  description = "Map of private network key to its assigned IPv4 CIDR, including subnets Scaleway allocated automatically."
  value       = { for k, pn in scaleway_vpc_private_network.this : k => try(pn.ipv4_subnet[0].subnet, null) }
}
