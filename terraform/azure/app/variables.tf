variable "project" {
  default = ""
  description = "Name of the GCP project to create resources in"
}

variable "location" {
  default = ""
  description = "Location of the GCP project to create resources in"
}

variable "cluster" {
  default = ""
  description = "Name of the Kubernetes cluster to deploy resources to"
}

variable "environment" {
  default = ""
  description = "Environment name for the application (e.g. dev, prod)"
}

variable "cloudflare_zone_id" {
  default = ""
  description = "Cloudflare zone ID for the domain to use"
}

variable "minecraft_admins" {
  default = {
    SheriffJackson = "642bf65a-0f3a-4c23-ac62-fefcb5fc420d"
  }
}

variable "boundary_addr" {
  default = "" 
  description = "Address of the Boundary server"
}

variable "boundary_user" {
  default = "" 
  description = "Username to configure the Boundary server scope"
}

variable "boundary_password" {
  default = "" 
  description = "Password to configure the Boundary server scope"
}

variable "boundary_credential_store_id" {
  default = "" 
  description = "ID of the boundary credential store that has been provisioned for the application"
}

variable "boundary_scope_id" {
  default = "" 
  description = "ID of the boundary scope id that has been provisioned for the application"
}

variable "boundary_user_accounts" {
  default = "" 
  description = "Username and account ids for the boundary users to be granted access to resources"
}

variable "vault_addr" {
  default = "" 
  description = "Address of the Vault server to use"
}

variable "vault_approle_id" {
  default = "" 
  description = "Vault AppRole ID to use for authentication to provision secrets and methods"
}

variable "vault_approle_secret_id" {
  default = "" 
  description = "Vault AppRole Secret ID to use for authentication"
}

variable "vault_approle_path" {
  default = "" 
  description = "Path to the approle auth method"
}

variable "vault_userpath_path" {
  default = "" 
  description = "Path to the userpass auth method provisioned for the application"
}

variable "vault_kubernetes_path" {
  default = "" 
  description = "Path to the kubernetes auth method provisioned for the application"
}

variable "vault_kv_path" {
  default = "" 
  description = "Path to the kv secrets engine provisioned for the application"
}

variable "vault_namespace" {
  default = "" 
  description = "The Vault namespace to use"
}

variable "lock_keys" {
  default = {
    admin = "myadminkey"
    vault = "myvaultkey"
  }
}
