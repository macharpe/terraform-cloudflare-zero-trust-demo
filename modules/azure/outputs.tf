output "azure_engineering_group_id" {
  description = "Group ID for engineering"
  value       = azuread_group.groups["engineering"].object_id
}

output "azure_sales_group_id" {
  description = "Group ID for Sales"
  value       = azuread_group.groups["sales"].object_id
}
