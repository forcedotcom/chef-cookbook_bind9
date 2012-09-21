#
# Cookbook Name:: bind9
# Recipe:: default
#
# Copyright 2011, Mike Adolphs
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

package "bind9" do
  case node[:platform]
  when "centos", "redhat", "suse", "fedora"
    package_name "bind"
  end
  action :install
end

directory node[:bind9][:data_path] do
  owner node[:bind9][:user]
  group node[:bind9][:user]
  mode 0750
end

directory "/var/log/bind/" do
  owner node[:bind9][:user]
  group node[:bind9][:user]
  mode 0755
end

service "bind9" do
  case node[:platform]
  when "centos", "redhat"
    service_name "named"
  end
  supports :status => true, :reload => true, :restart => true
  action [ :enable ]
end

service "bind9" do
  action :stop
end

template node[:bind9][:config_file] do
  source "named.conf.erb"
  owner "root"
  group node[:bind9][:user]
  mode 0644
  variables({
    :zonefiles => search(:zones)
  })

  notifies :restart, resources(:service => "bind9")
end

search(:zones).each do |zone|
  unless zone['autodomain'].nil? || zone['autodomain'] == ''
    search(:node, "domain:#{zone['autodomain']}").each do |host|
      next if host['ipaddress'] == '' || host['ipaddress'].nil?
        zone['zone_info']['records'].push( {
          "name" => host['hostname'],
          "type" => "A",
          "ip" => host['ipaddress']
        })
      end
  end

  file "#{node[:bind9][:data_path]}/#{zone['domain']}.jnl" do
    action :delete
  end

  template "#{node[:bind9][:data_path]}/#{zone['domain']}" do
    source "zonefile.erb"
    owner node[:bind9][:user]
    group node[:bind9][:user]
    mode 0644
    variables({
      :serial => Time.new.strftime("%Y%m%d%H%M%S"),
      :domain => zone['domain'],
      :soa => zone['zone_info']['soa'],
      :contact => zone['zone_info']['contact'],
      :global_ttl => zone['zone_info']['global_ttl'],
      :nameserver => zone['zone_info']['nameserver'],
      :mail_exchange => zone['zone_info']['mail_exchange'],
      :records => zone['zone_info']['records']
    })

    notifies :restart, resources(:service => "bind9")
  end
end

execute "disable_selinux" do
  command "echo 0 > /selinux/enforce"
  action :run
end

service "bind9" do
  action [ :start ]
end
