variable "users" {
  type = list(string)

  default = ["njackson"]
}

resource "boundary_scope" "minecraft" {
  scope_id = "global"
  name     = "minecraft"

  auto_create_admin_role   = true
  auto_create_default_role = true
}

resource "boundary_auth_method_password" "minecraft" {
  name        = "minecraft"
  description = "HCP Password Auth Method"
  scope_id    = boundary_scope.minecraft.id
}

# Create a random password for each user
resource "random_password" "password" {
  count = length(var.users)

  length           = 16
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

# create a map of user names to passwords 
locals {
  user_passwords = zipmap(var.users, random_password.password.*.result)
}

resource "boundary_account_password" "userpass" {
  for_each = local.user_passwords

  auth_method_id = boundary_auth_method_password.minecraft.id
  login_name     = each.key
  password       = each.value
}

resource "boundary_user" "user" {
  for_each = local.user_passwords

  name        = boundary_account_password.userpass[each.key].login_name
  account_ids = [boundary_account_password.userpass[each.key].id]
  scope_id    = boundary_scope.minecraft.id
}

# Creates the project and the credentials store
module "boundary_scope_dev" {
  source = "./boundary_project"

  org_id     = boundary_scope.minecraft.id
  scope_name = "minecraft-dev"

  vault_addr  = data.terraform_remote_state.hcp.outputs.vault_public_addr
  vault_token = data.terraform_remote_state.hcp.outputs.vault_admin_token
}

output "boundary_dev_details" {
  value = {
    credential_store_id = module.boundary_scope_dev.credential_store_id
    scope_id = module.boundary_scope_dev.scope_id
  }
}

output "boundary_users" {
  sensitive = true
  value = local.user_passwords
}