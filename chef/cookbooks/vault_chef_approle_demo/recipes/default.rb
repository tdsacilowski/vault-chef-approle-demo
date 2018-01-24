#
# Cookbook:: vault_chef_approle_demo
# Recipe:: default
#
# Copyright:: 2018, The Authors, All Rights Reserved.

# Vault Ruby client: https://github.com/hashicorp/vault-ruby
chef_gem 'vault' do
  compile_time true
end

require 'vault'

# Install Nginx
execute "apt-get update" do
  command "apt-get update"
end

package 'nginx' do
  action :install
end

service 'nginx' do
  action [ :enable, :start ]
end

# Get SecretID retrieval token from data bag
vault_token_data = data_bag_item('secretid-token', 'approle-secretid-token')
var_vault_token = vault_token_data['auth']['client_token']

# Vault connection info
Vault.address = ENV['VAULT_ADDR']
Vault.token   = var_vault_token

# Do Vault AppRole auth
var_role_id = ENV['APPROLE_ROLEID']
var_secret_id = Vault.approle.create_secret_id('app-1').data[:secret_id]
secret = Vault.auth.approle( var_role_id, var_secret_id )
var_approle_token = secret.auth.client_token

# Output our info
template '/var/www/html/index.html' do
  source 'index.html.erb'
  variables lazy {
    {
      role_id: var_role_id,
      secret_id: var_secret_id,
      approle_token: var_approle_token
    }
  }
end
