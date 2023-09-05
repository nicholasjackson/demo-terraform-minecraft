terraform {
  required_providers {
    hcp = {
      source  = "hashicorp/hcp"
      version = "~> 0.69.0"
    }
    
    terracurl = {
      source  = "devops-rob/terracurl"
      version = "1.0.1"
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
