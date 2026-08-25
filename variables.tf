variable "create" {
  type        = bool
  description = "Whether to create any resources. Set false to disable the module without removing the call."
  default     = true
}

variable "create_vpc" {
  type        = bool
  description = "Create a VPC. Set false and supply `vpc_id` to attach private networks to an existing VPC."
  default     = true
}

variable "vpc_id" {
  type        = string
  description = "Existing VPC to attach private networks to, used when `create_vpc` is false. Accepts the composite `{region}/{uuid}` form."
  default     = null
}

variable "name" {
  type        = string
  description = "Name of the VPC. Private networks are named `<name>-<key>` unless the key supplies its own `name`."
  default     = null
}

variable "region" {
  type        = string
  description = "Scaleway region. Defaults to the provider's region when null."
  default     = null
}

variable "project_id" {
  type        = string
  description = "Scaleway Project ID. Defaults to the provider's project when null."
  default     = null
}

variable "enable_routing" {
  type        = bool
  description = "Enable the VPC's managed routing table. Required for traffic between private networks and for Public Gateway default routes. Cannot be disabled once enabled."
  default     = true
}

variable "enable_custom_routes_propagation" {
  type        = bool
  description = "Propagate custom routes across the VPC's private networks."
  default     = null
}

variable "enable_transitivity" {
  type        = bool
  description = "Allow transitive routing between networks peered with this VPC."
  default     = null
}

variable "private_networks" {
  type = map(object({
    name                             = optional(string)
    subnet                           = optional(string)
    subnet_v6                        = optional(string)
    enable_default_route_propagation = optional(bool)
    tags                             = optional(map(string), {})
  }))
  description = <<-EOT
    Private networks to create, keyed by short name.

    `subnet` is the IPv4 CIDR. Scaleway constrains the prefix length to **/20../29
    inclusive**; anything wider is rejected at apply time with
    `subnets[0] is invalid for unexpected reason, prefix: {"min": 29, "max": 20}`.
    A /20 is the widest available and yields 4094 usable addresses.

    Omit `subnet` to let Scaleway allocate one automatically.

    Kapsule pins `private_network_id` immutably at cluster creation, so a key
    consumed by a cluster must never be renamed or re-CIDR'd in place.
  EOT
  default     = {}

  validation {
    condition = alltrue([
      for k, v in var.private_networks :
      v.subnet == null ? true : can(cidrhost(v.subnet, 0)) && tonumber(split("/", v.subnet)[1]) >= 20 && tonumber(split("/", v.subnet)[1]) <= 29
    ])
    error_message = "Each private network `subnet` must be a valid IPv4 CIDR with a prefix length between /20 and /29, which is the range Scaleway accepts."
  }
}

variable "tags" {
  type        = map(string)
  description = <<-EOT
    Tags applied to every resource.

    Scaleway takes tags as a list of strings rather than key/value pairs, and has
    no provider-level `default_tags`. This module accepts the conventional map and
    renders each entry as `key=value`, so callers can keep using a map.
  EOT
  default     = {}
}
