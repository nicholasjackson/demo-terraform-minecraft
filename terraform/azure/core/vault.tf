# Configure Vault for the environments
module "vault_namespace_dev" {
  source = "./vault_namespace"

  environment = "dev"
  userpass_usernames = var.vault_users
}

module "vault_namespace_test" {
  source = "./vault_namespace"

  environment = "test"
  userpass_usernames = var.vault_users
}

module "vault_namespace_prod" {
  source = "./vault_namespace"

  environment = "prod"
  userpass_usernames = var.vault_users
}

output "vault_userpass_dev" {
  sensitive = true
  value = module.vault_namespace_dev.userpass_user_details
}