#
# Cookbook:: vault_chef_approle_demo
# Recipe:: default
#
# Copyright:: 2018, The Authors, All Rights Reserved.

chef_gem 'vault' 
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

template '/var/www/html/index.html' do
  source 'index.html.erb'
  variables lazy {
    {
      roleid: ENV['APPROLE_ROLEID'],
      secretid: Vault.logical.read("auth/approle/role/app-1/secret-id")
    }
  }
end
