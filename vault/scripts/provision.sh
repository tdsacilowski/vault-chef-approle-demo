#!/usr/bin/env bash
set -x

##--------------------------------------------------------------------
## Initialize Vault

# Initialization payload
tee init.json <<EOF
{
    "secret_shares": 1,
    "secret_threshold": 1,
    "stored_shares": 1,
    "recovery_shares": 1,
    "recovery_threshold": 1,
    "key_shares": 1,
    "key_threshold": 1
}
EOF

# Initialize Vault
curl \
    --request PUT \
    --data @init.json \
    $VAULT_ADDR/v1/sys/init > init-response.json

export VAULT_TOKEN=$(cat init-response.json | jq -r .root_token)

##--------------------------------------------------------------------
## Configure Audit Backend

mkdir /home/ubuntu/vault-logs/
sudo chown vault:vault /home/ubuntu/vault-logs/

tee audit-backend-file.json <<EOF
{
  "type": "file",
  "options": {
    "path": "/home/ubuntu/vault-logs/vault-log.txt"
  }
}
EOF

curl \
    --header "X-Vault-Token: $VAULT_TOKEN" \
    --request PUT \
    --data @audit-backend-file.json \
    $VAULT_ADDR/v1/sys/audit/file-audit

sudo chmod -R 0777 /home/ubuntu/vault-logs/

##--------------------------------------------------------------------
## Create ACL Policies

# Policy to apply to AppRole token
tee app-1-secret-kv.json <<EOF
{"policy":"path \"secret/app-1/*\" {capabilities = [\"create\", \"read\", \"update\", \"delete\", \"list\"]}"}
EOF

# Write the policy
curl \
    --silent \
    --location \
    --header "X-Vault-Token: $VAULT_TOKEN" \
    --request PUT \
    --data @app-1-secret-kv.json \
    $VAULT_ADDR/v1/sys/policy/app-1-secret-kv

# Policy to get RoleID
tee app-1-auth-approle-roleid.json <<EOF
{"policy":"path \"auth/approle/role/app-1/role-id\" {capabilities = [\"read\"]}"}
EOF

# Write the policy
curl \
    --silent \
    --location \
    --header "X-Vault-Token: $VAULT_TOKEN" \
    --request PUT \
    --data @app-1-auth-approle-roleid.json \
    $VAULT_ADDR/v1/sys/policy/app-1-auth-approle-roleid

# Policy to get SecretID
tee app-1-auth-approle-secretid.json <<EOF
{"policy":"path \"auth/approle/role/app-1/secret-id\" {capabilities = [\"update\"]}"}
EOF

# Write the policy
curl \
    --silent \
    --location \
    --header "X-Vault-Token: $VAULT_TOKEN" \
    --request PUT \
    --data @app-1-auth-approle-secretid.json \
    $VAULT_ADDR/v1/sys/policy/app-1-auth-approle-secretid

# For Terraform
# See: https://www.terraform.io/docs/providers/vault/index.html#token
tee terraform-create-child-token.json <<EOF
{"policy":"path \"/auth/token/create\" {capabilities = [\"update\"]}"}
EOF

# Write the policy
curl \
    --silent \
    --location \
    --header "X-Vault-Token: $VAULT_TOKEN" \
    --request PUT \
    --data @terraform-create-child-token.json \
    $VAULT_ADDR/v1/sys/policy/terraform-create-child-token

# List ACL policies
curl \
    --location \
    --header "X-Vault-Token: $VAULT_TOKEN" \
    --request LIST \
    $VAULT_ADDR/v1/sys/policy | jq

##--------------------------------------------------------------------
## Enable & Configure AppRole Auth Backend

# AppRole auth backend config
tee approle.json <<EOF
{
  "type": "approle",
  "description": "Demo AppRole auth backend"
}
EOF

# Create the backend
curl \
    --silent \
    --location \
    --header "X-Vault-Token: $VAULT_TOKEN" \
    --request POST \
    --data @approle.json \
    $VAULT_ADDR/v1/sys/auth/approle

# AppRole backend configuration
tee app-1-approle-role.json <<EOF
{
    "role_name": "app-1",
    "bind_secret_id": true,
    "secret_id_ttl": "10m",
    "secret_id_num_uses": "1",
    "token_ttl": "10m",
    "token_max_ttl": "30m",
    "period": 0,
    "policies": [
        "app-1-secret-kv"
    ]
}
EOF

# Create the AppRole role
curl \
    --silent \
    --location \
    --header "X-Vault-Token: $VAULT_TOKEN" \
    --request POST \
    --data @app-1-approle-role.json \
    $VAULT_ADDR/v1/auth/approle/role/app-1

# Configure token for RoleID
tee token-roleid.json <<EOF
{
  "policies": [
    "app-1-auth-approle-roleid",
    "terraform-create-child-token"
  ],
  "metadata": {
    "user": "chef-demo"
  },
  "ttl": "720h",
  "renewable": true
}
EOF

# Get token
curl \
    --silent \
    --location \
    --header "X-Vault-Token: $VAULT_TOKEN" \
    --request POST \
    --data @token-roleid.json \
    $VAULT_ADDR/v1/auth/token/create > roleid-token.json

# Configure token for SecretID
tee token-secretid.json <<EOF
{
  "policies": [
    "app-1-auth-approle-secretid"
  ],
  "metadata": {
    "user": "chef-demo"
  },
  "ttl": "720h",
  "renewable": true
}
EOF

# Get token
curl \
    --silent \
    --location \
    --header "X-Vault-Token: $VAULT_TOKEN" \
    --request POST \
    --data @token-secretid.json \
    $VAULT_ADDR/v1/auth/token/create > secretid-token.json

cat roleid-token.json | jq -r .auth.client_token
cat secretid-token.json | jq -r .auth.client_token
