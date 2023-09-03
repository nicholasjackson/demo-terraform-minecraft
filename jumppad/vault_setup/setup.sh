#!/bin/sh

# Enable Vault userpass
vault auth enable userpass

# Create the example secrets
vault kv put secret/vault key="myvaultkey"
vault kv put secret/admin key="myadminkey"

# Create a policy for the user
cat <<EOF > user.hcl
path "secret/data/vault_local" {
  capabilities = ["read"]
}
EOF

vault policy write user user.hcl

# Create the admin policy
cat <<EOF > admin.hcl
path "secret/data/admin_local" {
  capabilities = ["read"]
}
EOF

vault policy write admin admin.hcl

# Create a user login
# When running in debug mode the user is not authenticted and is randomly generated every time
vault write "auth/userpass/users/SheriffJackson" password="642bf65a-0f3a-4c23-ac62-fefcb5fc420d" policies="user,admin"
