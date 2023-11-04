# Configure Vault for the environments
module "vault_namespace_dev" {
  source = "./vault_namespace"

  environment = "dev"
}

module "vault_namespace_test" {
  source = "./vault_namespace"

  environment = "test"
}

module "vault_namespace_prod" {
  source = "./vault_namespace"

  environment = "prod"
}