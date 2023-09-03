#!/bin/sh

# Mount the secrets engine
vault secrets enable -version=2 --path secrets_local kv 


# Enable Vault userpass
vault auth enable --path userpass_local userpass 

# Create the example secrets
vault kv put secrets_local/vault key="myvaultkey"
vault kv put secrets_local/admin key="myadminkey"

# Create a policy for the user
cat <<EOF > user.hcl
path "secrets_local/data/vault" {
  capabilities = ["read"]
}
EOF

vault policy write user user.hcl

# Create the admin policy
cat <<EOF > admin.hcl
path "secrets_local/data/admin" {
  capabilities = ["read"]
}
EOF

vault policy write admin admin.hcl

# Create a user login
# When running in debug mode the user is not authenticted and is randomly generated every time
vault write "auth/userpass_local/users/SheriffJackson" password="642bf65a-0f3a-4c23-ac62-fefcb5fc420d" policies="user,admin"
