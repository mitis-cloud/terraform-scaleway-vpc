# terraform-scaleway-vpc

Creates a Scaleway VPC and its private networks.

Small and composable by design: it manages the VPC and private networks and nothing
else. Pair it with
[`terraform-scaleway-public-gateway`](https://github.com/mitis-cloud/terraform-scaleway-public-gateway)
for NAT egress and
[`terraform-scaleway-kapsule-cluster`](https://github.com/mitis-cloud/terraform-scaleway-kapsule-cluster)
for Kubernetes.

## Usage

```hcl
module "vpc" {
  source  = "mitis-cloud/vpc/scaleway"
  version = "~> 1.0"

  name   = "platform"
  region = "fr-par"

  private_networks = {
    main = { subnet = "10.10.0.0/20" }
  }

  tags = {
    environment = "production"
  }
}
```

Attach private networks to a VPC you already have:

```hcl
module "vpc" {
  source  = "mitis-cloud/vpc/scaleway"
  version = "~> 1.0"

  create_vpc = false
  vpc_id     = "fr-par/68e629de-2140-4ee1-af80-bc917807f523"

  private_networks = {
    extra = { subnet = "10.10.32.0/22" }
  }
}
```

## Scaleway behaviour worth knowing

**Private network prefixes must be /20../29.** Anything wider is rejected at apply
time:

```
subnets[0] is invalid for unexpected reason, prefix: {"min": 29, "max": 20}
```

A `/20` is the widest available and gives 4094 usable addresses, which bounds how
many nodes or instances can share one network. The module validates this at plan
time so the failure is not deferred to apply. Omit `subnet` entirely to let Scaleway
allocate one.

**Tags are a list of strings.** Scaleway has no key/value tags and no provider-level
`default_tags`. This module accepts the conventional `map(string)` and renders each
entry as `key=value`, so callers keep a familiar interface and tagging does not have
to be reimplemented per resource.

**Resource IDs are composite.** Every Scaleway ID is `{region|zone}/{uuid}`. APIs and
modules differ on which form they want, so both are exported — `vpc_id` and
`private_network_ids` carry the composite form, `vpc_uuid` and `private_network_uuids`
the bare UUID.

**`enable_routing` cannot be turned off** once enabled. Kapsule and Public Gateway
default routes both depend on it, so it defaults to `true`.

**Private networks consumed by Kapsule are effectively immutable.** A cluster pins
`private_network_id` at creation; changing it replaces the entire cluster. Do not
rename or re-CIDR a key that a cluster uses.

## Examples

- [complete](examples/complete) — VPC with explicit, tagged and auto-allocated networks.

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.5.0 |
| scaleway | >= 2.81, < 3.0 |

## Providers

| Name | Version |
|------|---------|
| scaleway | 2.81.0 |

## Resources

| Name | Type |
|------|------|
| [scaleway_vpc.this](https://registry.terraform.io/providers/scaleway/scaleway/latest/docs/resources/vpc) | resource |
| [scaleway_vpc_private_network.this](https://registry.terraform.io/providers/scaleway/scaleway/latest/docs/resources/vpc_private_network) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| create | Whether to create any resources. Set false to disable the module without removing the call. | `bool` | `true` | no |
| create\_vpc | Create a VPC. Set false and supply `vpc_id` to attach private networks to an existing VPC. | `bool` | `true` | no |
| enable\_custom\_routes\_propagation | Propagate custom routes across the VPC's private networks. | `bool` | `null` | no |
| enable\_routing | Enable the VPC's managed routing table. Required for traffic between private networks and for Public Gateway default routes. Cannot be disabled once enabled. | `bool` | `true` | no |
| enable\_transitivity | Allow transitive routing between networks peered with this VPC. | `bool` | `null` | no |
| name | Name of the VPC. Private networks are named `<name>-<key>` unless the key supplies its own `name`. | `string` | `null` | no |
| private\_networks | Private networks to create, keyed by short name.<br/><br/>`subnet` is the IPv4 CIDR. Scaleway constrains the prefix length to **/20../29<br/>inclusive**; anything wider is rejected at apply time with<br/>`subnets[0] is invalid for unexpected reason, prefix: {"min": 29, "max": 20}`.<br/>A /20 is the widest available and yields 4094 usable addresses.<br/><br/>Omit `subnet` to let Scaleway allocate one automatically.<br/><br/>Kapsule pins `private_network_id` immutably at cluster creation, so a key<br/>consumed by a cluster must never be renamed or re-CIDR'd in place. | <pre>map(object({<br/>    name                             = optional(string)<br/>    subnet                           = optional(string)<br/>    subnet_v6                        = optional(string)<br/>    enable_default_route_propagation = optional(bool)<br/>    tags                             = optional(map(string), {})<br/>  }))</pre> | `{}` | no |
| project\_id | Scaleway Project ID. Defaults to the provider's project when null. | `string` | `null` | no |
| region | Scaleway region. Defaults to the provider's region when null. | `string` | `null` | no |
| tags | Tags applied to every resource.<br/><br/>Scaleway takes tags as a list of strings rather than key/value pairs, and has<br/>no provider-level `default_tags`. This module accepts the conventional map and<br/>renders each entry as `key=value`, so callers can keep using a map. | `map(string)` | `{}` | no |
| vpc\_id | Existing VPC to attach private networks to, used when `create_vpc` is false. Accepts the composite `{region}/{uuid}` form. | `string` | `null` | no |

## Outputs

| Name | Description |
|------|-------------|
| private\_network\_ids | Map of private network key to composite ID. |
| private\_network\_names | Map of private network key to resolved name. |
| private\_network\_subnets | Map of private network key to its assigned IPv4 CIDR, including subnets Scaleway allocated automatically. |
| private\_network\_uuids | Map of private network key to bare UUID. |
| vpc\_id | Composite ID of the VPC, in `{region}/{uuid}` form. Reflects `var.vpc_id` when the module did not create one. |
| vpc\_name | Name of the created VPC. |
| vpc\_uuid | Bare UUID of the VPC, for the Scaleway APIs that reject the composite form. |
<!-- END_TF_DOCS -->

## License

Apache 2.0. See [LICENSE](LICENSE).
