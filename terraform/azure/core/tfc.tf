data "tfe_project" "proj" {
  name = var.tfe_project
}

resource "tfe_workspace" "app-dev" {
  name         = "app-azure-dev"
  project_id = data.tfe_project.proj.id
 
  auto_apply   = true
  force_delete = true
}

resource "tfe_variable" "boundary_addr" {
  key          = "boundary_addr"
  value        = data.terraform_remote_state.hcp.outputs.boundary_cluster_url
  category     = "terraform"
  workspace_id = tfe_workspace.app-dev.id
  description  = "Address for the boundary cluster"
}

resource "tfe_variable" "boundary_credential_store_id" {
  key          = "boundary_credential_store_id"
  value        = module.boundary_scope_dev.credential_store_id
  category     = "terraform"
  workspace_id = tfe_workspace.app-dev.id
  description  = "Boundary credential store id for the app"
}

resource "tfe_variable" "boundary_user" {
  key          = "boundary_user"
  value        = data.terraform_remote_state.hcp.outputs.boundary_cluster_user
  category     = "terraform"
  workspace_id = tfe_workspace.app-dev.id
  description  = "User for the boundary cluster"
}

resource "tfe_variable" "boundary_password" {
  key          = "boundary_password"
  value        = data.terraform_remote_state.hcp.outputs.boundary_cluster_password
  category     = "terraform"
  workspace_id = tfe_workspace.app-dev.id
  description  = "Password for the boundary cluster"
  sensitive    = true
}

resource "tfe_variable" "boundary_scope_id" {
  key          = "boundary_scope_id"
  value        = module.boundary_scope_dev.scope_id
  category     = "terraform"
  workspace_id = tfe_workspace.app-dev.id
  description  = "Scope id for the boundary project"
}

resource "tfe_variable" "boundary_user_accounts" {
  key          = "boundary_user_accounts"
  value        = jsonencode(local.user_details)
  category     = "terraform"
  workspace_id = tfe_workspace.app-dev.id
  description  = "Boundary user accounts for the app"
  sensitive    = true
}

resource "tfe_variable" "environment" {
  key          = "environment"
  value        = "dev"
  category     = "terraform"
  workspace_id = tfe_workspace.app-dev.id
  description  = "Environment for the application"
}

resource "tfe_variable" "vault_addr" {
  key          = "vault_addr"
  value        = data.terraform_remote_state.hcp.outputs.vault_public_addr
  category     = "terraform"
  workspace_id = tfe_workspace.app-dev.id
  description  = "Vault address"
}

resource "tfe_variable" "vault_approle_id" {
  key          = "vault_approle_id"
  value        = module.vault_namespace_dev.approle_id
  category     = "terraform"
  workspace_id = tfe_workspace.app-dev.id
  description  = "Vault APP Role ID"
}

resource "tfe_variable" "vault_approle_path" {
  key          = "vault_approle_path"
  value        = module.vault_namespace_dev.approle_path
  category     = "terraform"
  workspace_id = tfe_workspace.app-dev.id
  description  = "Vault APP Role path"
}

resource "tfe_variable" "vault_approle_secret" {
  key          = "vault_approle_secret_id"
  value        = module.vault_namespace_dev.approle_secret_id
  category     = "terraform"
  workspace_id = tfe_workspace.app-dev.id
  description  = "Vault APP Role secret"
  sensitive    = true
}

resource "tfe_variable" "vault_kv_path" {
  key          = "vault_kv_path"
  value        = module.vault_namespace_dev.kv_path
  category     = "terraform"
  workspace_id = tfe_workspace.app-dev.id
  description  = "Vault KV path"
}

resource "tfe_variable" "vault_namespace" {
  key          = "vault_namespace"
  value        = module.vault_namespace_dev.namespace
  category     = "terraform"
  workspace_id = tfe_workspace.app-dev.id
  description  = "Vault namespace"
}

resource "tfe_variable" "vault_userpath_path" {
  key          = "vault_userpath_path"
  value        = module.vault_namespace_dev.userpath_path
  category     = "terraform"
  workspace_id = tfe_workspace.app-dev.id
  description  = "Vault userpath path"
}

resource "tfe_variable" "vault_kubernetes_path" {
  key          = "vault_kubernetes_path"
  value        = vault_auth_backend.dev.path
  category     = "terraform"
  workspace_id = tfe_workspace.app-dev.id
  description  = "Vault Kubernetes auth path"
}