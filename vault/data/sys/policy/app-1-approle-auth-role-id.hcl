path "auth/approle/role/app-1/role-id" {
  capabilities = ["read"]
}

# For Terraform
# See: https://www.terraform.io/docs/providers/vault/index.html#token
path "/auth/token/create" {
  capabilities = ["update"]
}
