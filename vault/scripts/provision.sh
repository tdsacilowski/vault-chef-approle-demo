#!/usr/bin/env bash
set -x

export VAULT_ADDR=http://127.0.0.1:8200
export VAULT_SKIP_VERIFY=true

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
tee app_1_secret_read.json <<EOF
{"policy":"path \"secret/app-1/*\" {capabilities = [\"read\", \"list\"]}"}
EOF

# Write the policy
curl \
    --silent \
    --location \
    --header "X-Vault-Token: $VAULT_TOKEN" \
    --request PUT \
    --data @app_1_secret_read \
    $VAULT_ADDR/v1/sys/policy/app_1_secret_read

##--------------------------------------------------------------------

# Policy to get RoleID
tee app_1_approle_roleid_get.json <<EOF
{"policy":"path \"auth/approle/role/app-1/role-id\" {capabilities = [\"read\"]}"}
EOF

# Write the policy
curl \
    --silent \
    --location \
    --header "X-Vault-Token: $VAULT_TOKEN" \
    --request PUT \
    --data @app_1_approle_roleid_get.json \
    $VAULT_ADDR/v1/sys/policy/app_1_approle_roleid_get

##--------------------------------------------------------------------

# Policy to get SecretID
tee app_1_approle_secretid_create.json <<EOF
{"policy":"path \"auth/approle/role/app-1/secret-id\" {capabilities = [\"update\"]}"}
EOF

# Write the policy
curl \
    --silent \
    --location \
    --header "X-Vault-Token: $VAULT_TOKEN" \
    --request PUT \
    --data @app_1_approle_secretid_create.json \
    $VAULT_ADDR/v1/sys/policy/app_1_approle_secretid_create

##--------------------------------------------------------------------

# For Terraform
# See: https://www.terraform.io/docs/providers/vault/index.html#token
tee terraform_token_create.json <<EOF
{"policy":"path \"/auth/token/create\" {capabilities = [\"update\"]}"}
EOF

# Write the policy
curl \
    --silent \
    --location \
    --header "X-Vault-Token: $VAULT_TOKEN" \
    --request PUT \
    --data @terraform_token_create.json \
    $VAULT_ADDR/v1/sys/policy/terraform_token_create

##--------------------------------------------------------------------

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
tee app_1_approle_role.json <<EOF
{
    "role_name": "app_1",
    "bind_secret_id": true,
    "secret_id_ttl": "10m",
    "secret_id_num_uses": "1",
    "token_ttl": "10m",
    "token_max_ttl": "30m",
    "period": 0,
    "policies": [
        "app_1_secret_read"
    ]
}
EOF

# Create the AppRole role
curl \
    --silent \
    --location \
    --header "X-Vault-Token: $VAULT_TOKEN" \
    --request POST \
    --data @app_1_approle_role.json \
    $VAULT_ADDR/v1/auth/approle/role/app_1

# Configure token for RoleID
tee roleid_token_config.json <<EOF
{
  "policies": [
    "app_1_approle_roleid_get",
    "terraform_token_create"
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
    --data @roleid_token_config.json \
    $VAULT_ADDR/v1/auth/token/create > roleid_token.json

# Configure token for SecretID
tee secretid_token_config.json <<EOF
{
  "policies": [
    "app_1_approle_secretid_create"
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
    --data @secretid_token_config.json \
    $VAULT_ADDR/v1/auth/token/create > secretid_token.json

cat roleid_token.json | jq -r .auth.client_token
cat secretid_token.json | jq -r .auth.client_token
