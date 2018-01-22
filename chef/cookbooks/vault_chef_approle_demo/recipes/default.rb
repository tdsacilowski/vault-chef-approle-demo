#
# Cookbook:: vault_chef_approle_demo
# Recipe:: default
#
# Copyright:: 2018, The Authors, All Rights Reserved.

chef_gem 'vault' do
  compile_time true
end

require 'vault'

execute "apt-get update" do
  command "apt-get update"
end

package 'nginx' do
  action :install
end

service 'nginx' do
  action [ :enable, :start ]
end

#
# Display Vault Values
#

Vault.address = "http://34.207.91.208:8200"
Vault.token   = "ccfb5ceb-8670-8005-5c4f-2ff3666be65d"

var_role_id = ENV['APPROLE_ROLEID']
var_secret_id = Vault.approle.create_secret_id('app-1').data[:secret_id]
secret = Vault.auth.approle( var_role_id, var_secret_id )
var_approle_token = secret.auth.client_token


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
