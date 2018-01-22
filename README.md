# Vault AppRole Example(s)

Work in progress...

This project is a working implementation of the concepts discussed in the _"Secure Introduction with Vault: AppRole + Chef" (link TBD)_ Guide/Blogpost. It aims to provide an end-to-end example of how to use Vault's [AppRole authentication backend](https://www.vaultproject.io/docs/auth/approle.html), along with Terraform & Chef, to address the challenge of _secure introduction_ of an initial token to a target server/application.

This project contains the following assets:

- Chef cookbook [`/chef`]: A sample cookbook with a recipe that installs Nginx and demonstrates Vault Ruby Gem functionality used to interact with Vault APIs.

- Terraform configurations:
    - [`/terraform/mgmt-node`]: Configuration to set up a management server running both Vault and Chef Server, for demo purposes.
    - [`/terraform/chef-node`]: Configuration to set up a Chef node and bootstrap it with the Chef Server, passing in Vault's AppRole RoleID and the appropriate Chef run-list.

- Vault configuration [`/vault`]: Data used to configure the appropriate mounts and policies in Vault for this demo.

## Provisioning Steps

Provisioning for this project happens in 2 phases:

1.) Vault + Chef Server
2.) Chef node (target system to which RoleID and SecretID are delivered)

### Vault + Chef Server

This provides a quick and simple configuration to help you get started (aka ___NOT SUITABLE FOR PRODUCTION USE!!___).

In this phase, we use Terraform to spin up a server with both Vault and Chef Server installed. Once this server is up and running, we'll complete the appropriate configuration steps in Vault and get our Chef admin key that will be used to bootstrap our Chef node (phase 2).

1.) `cd` into the `/terraform/mgmt-node` directory

2.) Make sure to update the `terraform.tfvars.example` file accordingly and rename to `terraform.tfvars`.
    - ___NOTE:___ this project assumes that a Vault Enterprise binary is being used so that we can take advantage of AWS KMS auto unseal functionality. To use the Open Source version of Vault, modify your `terraform.tfvars` and `/terraform/mgmt-node/templates/userdata-mgmt-node.tpl` files accordingly.
    - The Terraform output will display the public IP address to SSH into your server.
    - TODO: add the ability to switch between Enterprise and Open Source versions.

3.) Once you can access your Vault + Chef server, you'll see that we performed a `git clone` of this repository, to pull down the appropriate Chef cookbook(s) and Vault configurations:
- `/honme/ubuntu/vault-chef-approle-demo`: root of our Git repo.
- `/honme/ubuntu/vault-chef-approle-demo/chef`: root of our Chef app. This is where our `knife` configuration is located (`.chef/knife.rb`).
- `/honme/ubuntu/vault-chef-approle-demo/vault`: root of our Vault configurations. There's a `scripts/provision.sh` script to automate the provisioning, or you can follow along in the guide (linked above) to configure Vault manually.

Work in progress...
