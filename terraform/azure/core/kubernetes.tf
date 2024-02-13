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

# Create a service account so that Vault can create access tokens for the kubernetes
# cluster
resource "kubernetes_namespace" "vault" {
  metadata {
    name = "vault"
  }
}

resource "kubernetes_cluster_role" "vault" {
  metadata {
    name = "vault-permissions"
  }

  rule {
    api_groups = [""]
    resources  = ["namespaces"]
    verbs      = ["get"]
  }

  rule {
    api_groups = [""]
    resources  = ["serviceaccounts", "serviceaccounts/token"]
    verbs      = ["create", "update", "delete"]
  }

  rule {
    api_groups = ["rbac.authorization.k8s.io"]
    resources  = ["rolebindings", "clusterrolebindings"]
    verbs      = ["create", "update", "delete"]
  }
  rule {
    api_groups = ["rbac.authorization.k8s.io"]
    resources  = ["roles", "clusterroles"]
    verbs      = ["bind", "escalate", "create", "update", "delete"]
  }
}

resource "kubernetes_cluster_role_binding" "vault" {
  metadata {
    name = "vault-permissions"
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = kubernetes_cluster_role.vault.metadata.0.name
  }
  subject {
    kind      = "ServiceAccount"
    name      = "vault"
    namespace = "vault"
  }
}

resource "kubernetes_service_account" "vault" {
  metadata {
    name      = "vault"
    namespace = "vault"
  }
}

resource "kubernetes_secret_v1" "vault_sa_token" {
  metadata {
    generate_name = "vault-sa-token-"
    namespace     = kubernetes_namespace.vault.metadata.0.name
    annotations = {
      "kubernetes.io/service-account.name" = kubernetes_service_account.vault.metadata.0.name
    }
  }

  type = "kubernetes.io/service-account-token"
}

output "kubernetes_client_certificate" {
  value     = azurerm_kubernetes_cluster.cluster.kube_config.0.client_certificate
  sensitive = true
}

output "kubernetes_ca" {
  value     = azurerm_kubernetes_cluster.cluster.kube_config.0.cluster_ca_certificate
  sensitive = true
}

output "kubernetes_host" {
  value     = azurerm_kubernetes_cluster.cluster.kube_config.0.host
  sensitive = true
}

output "vault_sa_token" {
  value     = kubernetes_secret_v1.vault_sa_token.data.token
  sensitive = true
}

output "kube_config" {
  value = azurerm_kubernetes_cluster.cluster.kube_config_raw

  sensitive = true
}
