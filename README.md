# Vault AppRole Example(s)

This project aims to provide an end-to-end example of how to use Vault's [AppRole authentication backend](https://www.vaultproject.io/docs/auth/approle.html), along with Terraform & Chef, to address the challenge of _secure introduction_ of an initial token to a target server/application.

The project also currently applies the following patterns/features:

- Vault configuration and policy as code, based on [this blog post](https://www.hashicorp.com/blog/codifying-vault-policies-and-configuration.html)
- [AWS KMS auto unseal](https://www.vaultproject.io/docs/enterprise/auto-unseal/index.html) (requires Vault Enterprise)

Work in progress...