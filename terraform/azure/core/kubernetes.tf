resource "azurerm_kubernetes_cluster" "cluster" {
  name                = var.cluster
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
  dns_prefix          = var.cluster

  default_node_pool {
    name       = "default"
    node_count = 3
    vm_size    = "Standard_D2_v2"
  }

  identity {
    type = "SystemAssigned"
  }
}

resource "helm_release" "vault_controller" {
  name       = "vault-controller"

  repository = "https://helm.releases.hashicorp.com"
  chart      = "vault-secrets-operator"

  set {
    name = "defaultVaultConnection.enabled"
    value = "true"
  }
  
  set {
    name = "defaultVaultConnection.address"
    value = data.terraform_remote_state.hcp.outputs.vault_public_addr
  }
}

output "client_certificate" {
  value     = azurerm_kubernetes_cluster.cluster.kube_config.0.client_certificate
  sensitive = true
}

output "kube_config" {
  value = azurerm_kubernetes_cluster.cluster.kube_config_raw

  sensitive = true
}