#!/bin/sh

# Mount the secrets engine
vault secrets enable -version=2 --path secrets kv 

# Enable Vault userpass
vault auth enable --path userpass userpass 

# Create the example secrets
vault kv put secrets/vault key="myvaultkey"
vault kv put secrets/admin key="myadminkey"

# Create a policy for the user
cat <<EOF > user.hcl
path "secrets/data/vault" {
  capabilities = ["read"]
}
EOF

vault policy write user user.hcl

# Create the admin policy
cat <<EOF > admin.hcl
path "secrets/data/admin" {
  capabilities = ["read"]
}
EOF

vault policy write admin admin.hcl

# Create a user login
# When running in debug mode the user is not authenticted and is randomly generated every time
vault write "auth/userpass/users/SheriffJackson" password="642bf65a-0f3a-4c23-ac62-fefcb5fc420d" policies="user,admin"