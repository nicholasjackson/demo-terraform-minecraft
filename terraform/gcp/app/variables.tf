variable "project" {
  default = ""
}

variable "location" {
  default = ""
}

variable "cluster" {
  default = ""
}

variable "environment" {
  default = ""
}

variable "cloudflare_zone_id" {
  default = ""
}

variable "minecraft_admins" {
  default = {
    SheriffJackson = "642bf65a-0f3a-4c23-ac62-fefcb5fc420d"
  }
}

variable "boundary_scope_id" {
  default = "" 
}

variable "boundary_credential_store_id" {
  default = "" 
}

variable "boundary_credential_store_policy" {
  default = "" 
}

variable "vault_approle_id" {
  default = "" 
}

variable "vault_approle_secret_id" {
  default = "" 
}

variable "vault_approle_path" {
  default = "" 
}

variable "vault_userpath_path" {
  default = "" 
}

variable "vault_kv_path" {
  default = "" 
}

variable "vault_namespace" {
  default = "" 
}

variable "lock_keys" {
  default = {
    admin = "myadminkey"
    vault = "myvaultkey"
  }
}
