# Azure Active Directory Module

This module manages Azure Active Directory (Azure AD/Entra ID) users and groups for Zero Trust access control.

## Overview

The Azure module provides identity management capabilities:
- User creation and management in Azure AD
- Group membership configuration
- Integration with Cloudflare Access policies
- Support for contractor and employee differentiation

## Features

### User Management
- **Automated User Creation**: Bulk user provisioning
- **Password Management**: Secure password generation
- **User Principal Names**: Standardized UPN format
- **Display Names**: Consistent naming convention

### Group Management
- **Security Groups**: Role-based access groups
- **Dynamic Membership**: Automatic group assignment
- **Contractor Groups**: Separate contractor access
- **Employee Groups**: Standard employee access

## Usage

```hcl
module "azure" {
  source = "./modules/azure"

  # User configuration
  azure_contractor_user_principal_names = var.azure_contractor_user_principal_names
  azure_employee_user_principal_names   = var.azure_employee_user_principal_names

  # Group configuration
  azure_security_group_names = var.azure_security_group_names

  # Domain settings
  azure_ad_domain = var.azure_ad_domain
}
```

## Prerequisites

Before using this module:

1. **Azure AD Tenant**: Active Azure AD/Entra ID tenant
2. **Permissions**: User Administrator or Global Administrator role
3. **API Access**: Configured Azure AD Graph API permissions
4. **Domain**: Verified domain for user principal names

## Inputs

| Name | Type | Description | Required |
|------|------|-------------|----------|
| `azure_contractor_user_principal_names` | `list(string)` | List of contractor usernames | Yes |
| `azure_employee_user_principal_names` | `list(string)` | List of employee usernames | Yes |
| `azure_security_group_names` | `list(string)` | Security group names to create | Yes |
| `azure_ad_domain` | `string` | Azure AD domain for UPNs | Yes |

## Outputs

| Name | Description | Type |
|------|-------------|------|
| `user_object_ids` | Map of usernames to Azure AD object IDs | `map(string)` |
| `group_object_ids` | Map of group names to Azure AD object IDs | `map(string)` |
| `contractor_users` | List of created contractor users | `list(object)` |
| `employee_users` | List of created employee users | `list(object)` |

## Identity Integration

This module integrates with Cloudflare Access through:

### User Attributes
- **Object IDs**: Used in access policies
- **User Principal Names**: Email-based authentication
- **Group Memberships**: Role-based access control

### Access Policies
```hcl
# Example: Using Azure AD groups in Cloudflare policies
resource "cloudflare_access_policy" "contractor_policy" {
  application_id = cloudflare_access_application.app.id

  include {
    azure_ad {
      identity_provider_id = var.cf_idp_azuread_id
      group_ids = [module.azure.group_object_ids["contractors"]]
    }
  }
}
```

## Security Considerations

- **Password Policies**: Strong password requirements enforced
- **MFA**: Multi-factor authentication recommended
- **Conditional Access**: Azure AD policies can be applied
- **Audit Logging**: All user operations are logged
- **Least Privilege**: Users get minimal required permissions

## Best Practices

1. **Naming Conventions**: Use consistent user and group naming
2. **Group Structure**: Organize groups by role/department
3. **Regular Audits**: Review user access quarterly
4. **Password Rotation**: Implement password expiry policies
5. **Deprovisioning**: Remove users promptly when access ends

## Troubleshooting

### Common Issues

#### User Creation Failures
- Verify domain is verified in Azure AD
- Check for duplicate user principal names
- Ensure sufficient Azure AD licenses

#### Group Membership Issues
- Confirm user exists before group assignment
- Check Azure AD group membership limits
- Verify API permissions for group management

#### Authentication Problems
- Ensure Azure AD is configured as IdP in Cloudflare
- Verify user has valid license and is enabled
- Check conditional access policies

## Maintenance

Regular maintenance tasks:
- Review and remove inactive users
- Audit group memberships
- Update user attributes as needed
- Monitor sign-in logs for anomalies
- Sync with HR systems for user lifecycle

## Limitations

- Maximum 50,000 users per Azure AD tenant (default)
- Group membership changes may take up to 24 hours to propagate
- Nested group support depends on license tier
- Guest user support requires additional configuration

## Related Documentation

- [Azure AD Documentation](https://docs.microsoft.com/en-us/azure/active-directory/)
- [Azure AD Terraform Provider](https://registry.terraform.io/providers/hashicorp/azuread/latest/docs)
- [Cloudflare Azure AD Integration](https://developers.cloudflare.com/cloudflare-one/identity/idp-integration/azuread/)
- [Azure AD Best Practices](https://docs.microsoft.com/en-us/azure/active-directory/fundamentals/active-directory-deployment-checklist-p2)