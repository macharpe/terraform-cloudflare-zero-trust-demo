output "azure_engineering_group_id" {
  description = <<-EOT
    Azure AD Object ID for the Engineering security group.

    Purpose: Group identifier for role-based access control
    Usage: Reference in Cloudflare Access policies for engineering team access
    Format: UUID string (e.g., "12345678-1234-1234-1234-123456789012")
    Related: Used in access policies for engineering-specific applications
  EOT
  value       = azuread_group.groups["engineering"].object_id
}

output "azure_sales_group_id" {
  description = <<-EOT
    Azure AD Object ID for the Sales security group.

    Purpose: Group identifier for role-based access control
    Usage: Reference in Cloudflare Access policies for sales team access
    Format: UUID string (e.g., "12345678-1234-1234-1234-123456789012")
    Related: Used in access policies for sales-specific applications and resources
  EOT
  value       = azuread_group.groups["sales"].object_id
}
