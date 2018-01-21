#!/usr/bin/env bash
set -x

# Initialize Vault
vault init -stored-shares=1 -recovery-shares=1 -recovery-threshold=1 -key-shares=1 -key-threshold=1

# AppRole policy
tee te-policy-app-1.hcl <<EOF
path "secret/app-1/*" {
  capabilities = ["create", "read", "update", "delete", "list"]
}
EOF

# Write policy
vault write sys/policy/te-policy-app-1 policy=@te-policy-app-1.hcl

# Enable AppRole auth backend
vault auth-enable approle

# Create AppRole role and associate policy
vault write auth/approle/role/app-1 \
    secret_id_ttl=10m \
    token_num_uses=10 \
    token_ttl=20m \
    token_max_ttl=30m \
    secret_id_num_uses=1 \
    policies=te-policy-app-1

# Policy to retrieve Secret ID for AppRole
tee te-policy-app-1-secretID.hcl <<EOF
path "auth/approle/role/app-1/secret-id" {
    capabilities = ["update"]
}
EOF

# Write policy
vault write sys/policy/te-policy-app-1-secretID \
    policy=@te-policy-app-1-secretID.hcl

# Policy to retrieve Role ID for AppRole
tee te-policy-app-1-roleID.hcl <<EOF
path "auth/approle/role/app-1/role-id" {
    capabilities = ["read"]
}
# For Terraform
# See: https://www.terraform.io/docs/providers/vault/index.html#token
path "/auth/token/create" {
    capabilities = ["update"]
}
EOF

# Write policy
vault write sys/policy/te-policy-app-1-roleID \
    policy=@te-policy-app-1-roleID.hcl

# Token to retrieve Secret IDs
vault token-create -policy="te-policy-app-1-secretID"

# Token to retrieve Role IDs
vault token-create -policy="te-policy-app-1-roleID"
