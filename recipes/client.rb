#
# Author:: Matt Ray <matt@@chef.io>
# Cookbook Name:: chrony
# Recipe:: client
# Copyright:: 2011-2018 Chef Software, Inc.
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

package node['chrony']['package']

service node['chrony']['service'] do
  supports restart: true, status: true, reload: true
  action [ :enable ]
end

# clients aren't servers by default
node.default['chrony']['allow'] = []

# search for the chrony master(s), if found populate the template accordingly
# typical deployment will only have 1 master, but still allow for multiple
masters = []
masters = search(:node, 'recipes:chrony\:\:master') if node['chrony']['discover_chrony_servers']
if !masters.empty?
  node.default['chrony']['servers'] = {}
  masters.each do |master|
    node.default['chrony']['servers'][master['ipaddress']] = master['chrony']['server_options']
    node.default['chrony']['allow'].push "allow #{master['ipaddress']}"
    # only use 1 server to sync initslewstep
    node.default['chrony']['initstepslew'] = "initstepslew 20 #{master['ipaddress']}"
  end
else
  Chef::Log.info('No chrony master(s) found, using node[:chrony][:servers] & node[:chrony][:pools] attribute.') unless node['chrony']['discover_chrony_servers']
end

template node['chrony']['conffile'] do
  owner 'root'
  group 'root'
  mode '0644'
  source 'chrony.conf.erb'
  notifies :restart, "service[#{node['chrony']['service']}]"
end
