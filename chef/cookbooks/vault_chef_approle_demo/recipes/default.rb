#
# Cookbook:: vault_chef_approle_demo
# Recipe:: default
#
# Copyright:: 2018, The Authors, All Rights Reserved.

apt_update 'Update the apt cache daily' do
    frequency 86_400
    action :periodic
  end
  
  package 'nginx'
  
  service 'nginx' do
    supports status: true
    action [:enable, :start]
  end
  
  template '/var/www/html/index.html' do # ~FC033
    source 'index.html.erb'
  end