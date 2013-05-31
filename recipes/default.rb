include_recipe "apt"
include_recipe "node::apt"
include_recipe "deploy_wrapper"
include_recipe "runit"

require "set"
package "git-core"

service "dreadnot" do
  restart_command "sv restart dreadnot"
  supports :restart => true
end

directory node[:dreadnot][:path] do
  owner 'root'
  group 'root'
  mode 0755
  recursive true
end

directory '/root/.ssh' do
  owner 'root'
  group 'root'
  mode 0700
end

template ::File.join(node[:dreadnot][:path],'local_settings.js') do
    source 'local_settings.js.erb'
    mode 0750
    owner 'root'
    group 'root'
    variables( :dreadnot => node[:dreadnot] )
    notifies :restart, "service[dreadnot]"
end

directory "/root/.chef/" do
    owner "root"
    group "root"
    mode 0700
end

template '/root/.chef/knife.rb' do
    source 'knife.rb.erb'
    mode 0750
    owner 'root'
    group 'root'
end

template '/root/.ssh/config' do
  source 'ssh_config.erb'
  mode 0700
  owner 'root'
  group 'root'
end

node_npm "https://github.com/needle/dreadnot/tarball/master" do
    action :install
    notifies :restart, "service[dreadnot]"
end

link ::File.join(node[:dreadnot][:path],"/stacks") do
    to ::File.join(node[:dreadnot][:path],"/current")
end

runit_service "dreadnot"
