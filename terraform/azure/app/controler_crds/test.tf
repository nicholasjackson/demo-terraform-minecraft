resource "kubernetes_manifest" "vaultauth_dev_auth" {
  manifest = {
    "apiVersion" = "secrets.hashicorp.com/v1beta1"
    "kind" = "VaultAuth"
    "metadata" = {
      "name" = "dev-auth"
    }
    "spec" = {
      "allowedNamespaces" = [
        "*",
      ]
      "kubernetes" = {
        "role" = "minecraft"
        "serviceAccount" = "minecraft-dev"
        "tokenExpirationSeconds" = 600
      }
      "method" = "kubernetes"
      "mount" = "kubernetes"
      "namespace" = "admin/dev"
      "vaultConnectionRef" = "default"
    }
  }
}