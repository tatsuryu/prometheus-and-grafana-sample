#
# Cookbook Name:: janek
# Recipe:: prometheus
#
# Copyright 2018, Willian Braga da Silva
#
# All rights reserved - Do Not Redistribute
#

node_exporter_release = "#{node['prometheus']['node_exporter']['version']}.#{node['prometheus']['node_exporter']['arch']}"

remote_file "/usr/src/node_exporter-#{node_exporter_release}.tar.gz" do
  source "https://github.com/prometheus/node_exporter/releases/download/v0.15.2/node_exporter-0.15.2.linux-amd64.tar.gz"
  source "https://github.com/prometheus/node_exporter/releases/download/v#{node['prometheus']['node_exporter']['version']}/node_exporter-#{node_exporter_release}.tar.gz"
  owner node['prometheus']['user_definition']['name']
  group node['prometheus']['user_definition']['name']
  mode '0755'
  action :create
  notifies :run, 'bash[extract_node_exporter]', :immediately
end

bash 'extract_node_exporter' do
  cwd '/usr/src/'
  code <<-EOH
    tar xzf node_exporter-#{node_exporter_release}.tar.gz
    cp node_exporter-#{node_exporter_release}/node_exporter #{node['prometheus']['node_exporter']['bin_dir']}
    EOH
  action :nothing
end

template '/lib/systemd/system/node_exporter.service' do
  source 'node_exporter.service.erb'
  owner node['prometheus']['user_definition']['name']
  group node['prometheus']['user_definition']['name']
  mode '0644'      
  notifies :reload, "service[node_exporter]", :immediately
  variables(bin_dir: node['prometheus']['node_exporter']['bin_dir'],
    user: node['prometheus']['user_definition']['name'],
  )
end

service 'node_exporter' do
  action [:enable, :start]
  supports :restart => true, :reload => true
  subscribes :reload, 'template[/lib/systemd/system/node_exporter.service]', :immediately
end
