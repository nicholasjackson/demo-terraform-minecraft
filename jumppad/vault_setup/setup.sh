#!/bin/sh

# Enable Vault userpass
vault auth enable userpass

# Create the example secrets
vault kv put secret/vault key="myvaultkey"
vault kv put secret/admin key="myadminkey"

# Create a policy for the user
cat <<EOF > user.hcl
path "secret/data/vault" {
  capabilities = ["read"]
}
EOF

vault policy write user user.hcl

# Create the admin policy
cat <<EOF > admin.hcl
path "secret/data/admin" {
  capabilities = ["read"]
}
EOF

vault policy write admin admin.hcl

# Create a user login
# When running in debug mode the user is not authenticted and is randomly generated every time
vault write "auth/userpass/users/Player844" password="bd0d6de2-7897-388f-8c0f-71e10002b81c" policies="user,admin"