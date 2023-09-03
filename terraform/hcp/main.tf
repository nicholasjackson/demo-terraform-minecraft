terraform {
  required_providers {
    hcp = {
      source  = "hashicorp/hcp"
      version = "~> 0.69.0"
    }
  }
  
  cloud {
    organization = "HashiCraft"

    workspaces {
      name = "HCP"
    }
  }
}

provider "hcp" {
  # Configuration options
}