# SSH Keys Module

This module generates and manages SSH key pairs for secure access to virtual machines across all cloud providers.

## Overview

The Keys module provides centralized SSH key management:
- Automated key pair generation for each VM instance
- Secure key storage and distribution
- Support for multiple cloud providers
- Consistent key naming and organization

## Features

### Key Generation
- **RSA 4096-bit Keys**: High-security key pairs
- **Unique Keys per Instance**: Individual keys for each VM
- **Automatic Generation**: Keys created during terraform apply
- **PEM Format**: Standard format for all platforms

### Multi-Cloud Support
- **AWS EC2**: Key pairs for all EC2 instances
- **Azure VMs**: SSH keys for Linux virtual machines
- **GCP Compute**: SSH keys for Compute Engine instances

## Usage

```hcl
module "ssh_keys" {
  source = "./modules/keys"

  # AWS configuration
  aws_key_pair_count = var.aws_ec2_instance_count

  # Azure configuration
  azure_key_pair_count = var.azure_vm_count

  # GCP configuration
  gcp_key_pair_count = var.gcp_vm_warp_instance_count +
                       var.gcp_vm_cloudflared_instance_count +
                       var.gcp_vm_windows_instance_count
}
```

## Inputs

| Name | Type | Description | Default |
|------|------|-------------|---------|
| `aws_key_pair_count` | `number` | Number of AWS SSH key pairs to generate | `3` |
| `azure_key_pair_count` | `number` | Number of Azure SSH key pairs to generate | `2` |
| `gcp_key_pair_count` | `number` | Number of GCP SSH key pairs to generate | `3` |

## Outputs

| Name | Description | Type | Sensitive |
|------|-------------|------|-----------|
| `aws_ssh_public_key` | List of public keys for AWS instances | `list(string)` | No |
| `aws_ssh_private_key` | List of private keys for AWS instances | `list(string)` | Yes |
| `azure_ssh_public_key` | List of public keys for Azure VMs | `list(string)` | No |
| `azure_ssh_private_key` | List of private keys for Azure VMs | `list(string)` | Yes |
| `gcp_ssh_public_key` | List of public keys for GCP instances | `list(string)` | No |
| `gcp_ssh_private_key` | List of private keys for GCP instances | `list(string)` | Yes |

## Security Best Practices

### Key Storage
- **Never Commit Private Keys**: Private keys are marked sensitive
- **Use Secret Management**: Store keys in vault/secret manager
- **Terraform State**: Ensure state file is encrypted
- **Access Control**: Limit who can access terraform outputs

### Key Rotation
- **Regular Rotation**: Rotate keys quarterly
- **Incident Response**: Rotate immediately if compromised
- **Audit Trail**: Log all key access and usage
- **Decommission**: Remove old keys after rotation

### Access Patterns
```bash
# Save private key securely (example)
terraform output -raw aws_ssh_private_key_0 > ~/.ssh/aws-vm-0.pem
chmod 600 ~/.ssh/aws-vm-0.pem

# Connect to instance
ssh -i ~/.ssh/aws-vm-0.pem ubuntu@<instance-ip>
```

## Integration with Cloud Providers

### AWS Integration
```hcl
resource "aws_key_pair" "ssh_key" {
  count      = var.aws_ec2_instance_count
  key_name   = "cloudflare-demo-key-${count.index}"
  public_key = module.ssh_keys.aws_ssh_public_key[count.index]
}
```

### Azure Integration
```hcl
resource "azurerm_linux_virtual_machine" "vm" {
  admin_ssh_key {
    username   = var.admin_username
    public_key = module.ssh_keys.azure_ssh_public_key[count.index]
  }
}
```

### GCP Integration
```hcl
resource "google_compute_instance" "vm" {
  metadata = {
    ssh-keys = "${var.ssh_user}:${module.ssh_keys.gcp_ssh_public_key[count.index]}"
  }
}
```

## Key Management Lifecycle

1. **Generation**: Keys created on `terraform apply`
2. **Distribution**: Public keys deployed to VMs
3. **Storage**: Private keys in terraform state
4. **Access**: Retrieved via `terraform output`
5. **Rotation**: Recreate resources for new keys
6. **Cleanup**: Keys removed on `terraform destroy`

## Troubleshooting

### SSH Connection Issues
```bash
# Verify key permissions
ls -la ~/.ssh/
# Should show: -rw------- (600) for private keys

# Test connection with verbose output
ssh -vvv -i ~/.ssh/key.pem user@host

# Check SSH agent
ssh-add -l
```

### Key Format Problems
- Ensure PEM format for compatibility
- Convert if needed: `ssh-keygen -f key -m pem`
- Verify key: `ssh-keygen -l -f key.pem`

### Permission Denied
- Check VM security groups/firewall rules
- Verify correct username for OS
- Ensure public key is in authorized_keys

## Cleanup

To clean SSH known_hosts after infrastructure changes:
```bash
# Use provided cleanup script
python3 scripts/cleanup/known_hosts_cleanup.py

# Or manually remove entries
ssh-keygen -R <hostname-or-ip>
```

## Limitations

- RSA 4096-bit only (no ED25519 support currently)
- Keys stored in Terraform state (ensure encryption)
- No automatic rotation mechanism
- One key per instance (no key sharing)

## Future Enhancements

- [ ] Support for ED25519 keys
- [ ] Integration with AWS Systems Manager
- [ ] Azure Key Vault integration
- [ ] GCP Secret Manager support
- [ ] Automatic key rotation
- [ ] Certificate-based authentication

## Related Documentation

- [OpenSSH Documentation](https://www.openssh.com/manual.html)
- [AWS EC2 Key Pairs](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ec2-key-pairs.html)
- [Azure SSH Keys](https://docs.microsoft.com/en-us/azure/virtual-machines/linux/ssh-from-windows)
- [GCP SSH Keys](https://cloud.google.com/compute/docs/instances/adding-removing-ssh-keys)