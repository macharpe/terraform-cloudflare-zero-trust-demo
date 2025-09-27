# WARP Routing Module

This module calculates and manages CIDR subnet allocations for WARP connector routing across cloud providers.

## Overview

The WARP Routing module provides intelligent subnet allocation:
- Automatic CIDR calculation for WARP networks
- Non-overlapping subnet generation
- Consistent IP addressing across clouds
- Support for future network expansion

## Features

### Subnet Calculation
- **Automatic Allocation**: Generates /24 subnets from base CIDR
- **Non-Overlapping**: Ensures no IP conflicts between clouds
- **Predictable Addressing**: Consistent subnet numbering
- **Scalable Design**: Room for additional subnets

### Network Architecture
```
Base CIDR: 100.96.0.0/12 (CGNAT Range)
├── Azure WARP: 100.96.1.0/24
├── GCP WARP:   100.96.2.0/24
├── AWS WARP:   100.96.3.0/24 (future)
└── Reserved:   100.96.4.0/24+ (expansion)
```

## Usage

```hcl
module "warp_routing" {
  source = "./modules/warp-routing"

  # Base configuration
  cf_warp_cgnat_cidr = var.cf_warp_cgnat_cidr  # e.g., "100.96.0.0/12"
  warp_subnet_size   = 24                       # Size of each subnet
}

# Using the outputs
resource "azurerm_route_table" "warp_routes" {
  route {
    name           = "route-to-warp"
    address_prefix = module.warp_routing.azure_warp_cidr
    next_hop_type  = "VirtualAppliance"
  }
}
```

## Inputs

| Name | Type | Description | Default |
|------|------|-------------|---------|
| `cf_warp_cgnat_cidr` | `string` | Base CGNAT CIDR for WARP (100.96.0.0/12) | Required |
| `warp_subnet_size` | `number` | Size of each WARP subnet (bits) | `24` |

## Outputs

| Name | Description | Example |
|------|-------------|---------|
| `azure_warp_cidr` | CIDR for Azure WARP connector | `100.96.1.0/24` |
| `gcp_warp_cidr` | CIDR for GCP WARP connector | `100.96.2.0/24` |
| `aws_warp_cidr` | CIDR for AWS WARP connector (future) | `100.96.3.0/24` |
| `base_network` | Base network address | `100.96.0.0` |
| `subnet_mask` | Calculated subnet mask | `255.255.255.0` |

## Network Design

### CGNAT Address Space
The module uses Carrier-Grade NAT (CGNAT) RFC 6598 address space:
- **Range**: 100.64.0.0/10
- **Our Allocation**: 100.96.0.0/12
- **Purpose**: Private routing between WARP clients and cloud resources

### Subnet Allocation Strategy
```hcl
# Automatic calculation based on index
cidrsubnet(base_cidr, new_bits, index)

# Results in:
Azure: cidrsubnet("100.96.0.0/12", 12, 1) = 100.96.1.0/24
GCP:   cidrsubnet("100.96.0.0/12", 12, 2) = 100.96.2.0/24
AWS:   cidrsubnet("100.96.0.0/12", 12, 3) = 100.96.3.0/24
```

## Routing Configuration

### Azure Routes
```hcl
# Route table for Azure WARP traffic
resource "azurerm_route_table" "warp" {
  route {
    name                   = "warp-cgnat"
    address_prefix         = var.cf_warp_cgnat_cidr
    next_hop_type          = "VirtualAppliance"
    next_hop_in_ip_address = azurerm_network_interface.warp_connector.private_ip_address
  }
}
```

### GCP Routes
```hcl
# Route for GCP WARP traffic
resource "google_compute_route" "warp" {
  name        = "warp-cgnat-route"
  dest_range  = var.cf_warp_cgnat_cidr
  network     = google_compute_network.vpc.id
  next_hop_ip = google_compute_instance.warp_connector.network_interface[0].network_ip
}
```

### AWS Routes (Future)
```hcl
# Route table for AWS WARP traffic
resource "aws_route" "warp" {
  route_table_id         = aws_route_table.private.id
  destination_cidr_block = var.cf_warp_cgnat_cidr
  network_interface_id   = aws_network_interface.warp_connector.id
}
```

## WARP Connector Integration

### Connector Configuration
The WARP connector uses these subnets to:
1. **Advertise Routes**: Announce cloud VPC CIDRs to WARP
2. **Receive Traffic**: Accept connections from WARP clients
3. **Forward Packets**: Route between WARP and VPC resources

### Traffic Flow
```
WARP Client (100.96.x.x)
    ↓
Cloudflare Edge
    ↓
WARP Connector (Cloud VM)
    ↓
Cloud Resources (VPC CIDR)
```

## Best Practices

1. **Non-Overlapping CIDRs**: Ensure VPC CIDRs don't overlap with WARP
2. **Subnet Sizing**: Use /24 for most deployments (254 hosts)
3. **Documentation**: Document all CIDR allocations
4. **Reserved Ranges**: Keep subnets for future expansion
5. **Monitoring**: Track IP utilization in each subnet

## Troubleshooting

### Routing Issues
```bash
# Check routing table on WARP connector
ip route show

# Verify WARP tunnel status
warp-cli status

# Test connectivity
ping -c 4 100.96.1.1

# Trace route path
traceroute 100.96.1.1
```

### Common Problems

#### No Connectivity
- Verify WARP connector is running
- Check cloud security groups/firewall rules
- Ensure routes are properly configured
- Validate WARP tunnel is connected

#### IP Conflicts
- Check for overlapping CIDRs
- Verify unique subnet allocation
- Review VPC peering configurations
- Audit all route tables

#### Asymmetric Routing
- Ensure return path uses WARP connector
- Check for multiple default routes
- Verify NAT configurations
- Review cloud route priorities

## Advanced Configuration

### Custom Subnet Sizes
```hcl
# For larger deployments, use /23 or /22
module "warp_routing" {
  source = "./modules/warp-routing"

  cf_warp_cgnat_cidr = "100.96.0.0/12"
  warp_subnet_size   = 23  # 510 hosts per subnet
}
```

### Multi-Region Support
```hcl
# Regional WARP subnets
module "warp_routing_us" {
  source = "./modules/warp-routing"

  cf_warp_cgnat_cidr = "100.96.0.0/14"  # US Region
}

module "warp_routing_eu" {
  source = "./modules/warp-routing"

  cf_warp_cgnat_cidr = "100.100.0.0/14" # EU Region
}
```

## Limitations

- Fixed to CGNAT address space (100.64.0.0/10)
- Maximum 16 /24 subnets with default configuration
- No dynamic subnet resizing after deployment
- Requires manual route configuration in each cloud

## Future Enhancements

- [ ] Dynamic subnet sizing based on requirements
- [ ] Automatic route propagation via BGP
- [ ] IPv6 support for WARP routing
- [ ] Multi-region subnet allocation
- [ ] Integration with cloud native routing services

## Related Documentation

- [Cloudflare WARP Routing](https://developers.cloudflare.com/cloudflare-one/connections/connect-devices/warp/deployment/firewall/)
- [RFC 6598 - CGNAT Address Space](https://tools.ietf.org/html/rfc6598)
- [CIDR Notation](https://en.wikipedia.org/wiki/Classless_Inter-Domain_Routing)
- [IP Subnet Calculator](https://www.subnet-calculator.com/)