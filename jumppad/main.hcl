resource "network" "local" {
  subnet = "10.10.0.0/16"
}

resource "container" "vault" {
  image {
    name = "hashicorp/vault:${variable.vault_version}"
  }

  command = [
    "vault",
    "server",
    "-dev",
    "-dev-root-token-id=${variable.vault_root_token}",
    "-dev-listen-address=0.0.0.0:8200",
    "-dev-plugin-dir=/plugins"
  ]

  port {
    local           = 8200
    remote          = 8200
    host            = 8200
    open_in_browser = ""
  }

  privileged = true

  # Wait for Vault to start
  health_check {
    timeout = "120s"
    http {
      address       = "http://localhost:8200/v1/sys/health"
      success_codes = [200]
    }
  }

  environment = {
    VAULT_ADDR  = "http://localhost:8200"
    VAULT_TOKEN = variable.vault_root_token
  }

  network {
    id         = resource.network.local.id
    ip_address = variable.vault_ip_address
  }

  volume {
    source      = variable.vault_data
    destination = "/data"
  }

  volume {
    source      = variable.vault_plugin_folder
    destination = "/plugins"
  }

  volume {
    source      = "../"
    destination = "/output"
  }

  volume {
    source      = variable.vault_additional_volume.source
    destination = variable.vault_additional_volume.destination
    type        = variable.vault_additional_volume.type
  }
}

resource "remote_exec" "vault_bootstrap" {
  target            = resource.container.vault
  script            = file("./vault_setup/setup.sh")
  working_directory = "/data"
}

output "VAULT_ADDR" {
  value = "http://localhost:8200"
}

output "VAULT_TOKEN" {
  value = "root"
}