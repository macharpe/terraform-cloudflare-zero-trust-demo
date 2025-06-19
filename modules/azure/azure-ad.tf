#==========================================================
# Local Variables
#==========================================================
locals {
  groups = ["engineering", "sales"]

  users = {
    developer1 = { name = var.azure_developer1_name, group = "engineering" }
    developer2 = { name = var.azure_developer2_name, group = "engineering" }
    sales1     = { name = var.azure_sales1_name, group = "sales" }
    sales2     = { name = var.azure_sales2_name, group = "sales" }
  }
}

#==========================================================
# Group Configuration
#==========================================================
resource "azuread_group" "groups" {
  for_each         = toset(local.groups)
  display_name     = "Azure_${each.key}"
  security_enabled = true
}

#==========================================================
# Create Users
#==========================================================
resource "azuread_user" "users" {
  for_each            = local.users
  user_principal_name = "${each.value.name}@${var.azure_user_principal_domain}"
  display_name        = each.value.name
  mail_nickname       = each.value.name
  password            = var.azure_user_password
}

#==========================================================
# Assign users to groups
#==========================================================
resource "azuread_group_member" "user_memberships" {
  for_each         = local.users
  group_object_id  = azuread_group.groups[each.value.group].object_id
  member_object_id = azuread_user.users[each.key].object_id
}

resource "azuread_group_member" "matthieu_member" {
  group_object_id  = azuread_group.groups["sales"].object_id
  member_object_id = var.azure_matthieu_user_object_id
}
