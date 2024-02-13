variable "project" {
  default = ""
}

variable "location" {
  default = ""
}

variable "cluster" {
  default = ""
}

variable "environments" {
  default = ["dev", "test", "prod"]
}

variable "tfe_organization" {
  default = "HashiCraft" 
}

variable "tfe_project" {
  default = "terraform-for-developers" 
}

variable "vault_users" {
  default = []  
}