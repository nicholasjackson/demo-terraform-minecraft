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
  name = "vault-controller"

  repository = "https://helm.releases.hashicorp.com"
  chart      = "vault-secrets-operator"

  set {
    name  = "defaultVaultConnection.enabled"
    value = "true"
  }

  set {
    name  = "defaultVaultConnection.address"
    value = data.terraform_remote_state.hcp.outputs.vault_public_addr
  }
}

// configure the vault kubernetes auth backend
resource "vault_auth_backend" "dev" {
  type      = "kubernetes"
  namespace = module.vault_namespace_dev.namespace
}

# define the backend configuration
resource "vault_kubernetes_auth_backend_config" "dev" {
  backend   = vault_auth_backend.dev.path
  namespace = module.vault_namespace_dev.namespace

  kubernetes_host    = azurerm_kubernetes_cluster.cluster.kube_config.0.host
  kubernetes_ca_cert = base64decode(azurerm_kubernetes_cluster.cluster.kube_config.0.cluster_ca_certificate)
}

output "client_certificate" {
  value     = azurerm_kubernetes_cluster.cluster.kube_config.0.client_certificate
  sensitive = true
}

output "kube_config" {
  value = azurerm_kubernetes_cluster.cluster.kube_config_raw

  sensitive = true
}
