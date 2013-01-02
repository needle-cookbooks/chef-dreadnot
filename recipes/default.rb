include_recipe "apt"
include_recipe "node::apt"
include_recipe "base::deploy"
include_recipe "deploy_wrapper"
include_recipe "runit"

require "set"

partners = Set.new()
search(:node, "chef_environment:#{node.chef_environment} AND roles:core") do |node|
  node['core']['partners'].each do |partner|
    partners.add(partner)
  end
end

secrets = Secrets.load(node['data_bag_key'],node.chef_environment)

directory '/opt/needle/shared' do
  owner 'root'
  group 'root'
  mode 0755
end

directory node[:dreadnot][:path] do
  owner 'root'
  group 'root'
  mode 0755
end

deploy_wrapper "dreadnot" do
  ssh_wrapper_dir '/opt/needle/shared'
  ssh_key_dir '/root/.ssh'
  ssh_key_data secrets['deploy_keys']['dreadnot']
  sloppy true
end

service "dreadnot" do
  restart_command "sv restart dreadnot"
  supports :restart => true
end

template ::File.join(node[:dreadnot][:path],'local_settings.js') do
    source 'local_settings.js.erb'
    mode 0750
    owner 'root'
    group 'root'
    variables( :dreadnot => node[:dreadnot], :secrets => secrets,
      :partners => partners)
    notifies :restart, "service[dreadnot]"
end

template '/opt/needle/shared/redeploy_ssh_wrapper.sh' do
    source 'redeploy_ssh_wrapper.sh.erb'
    mode 0750
    owner 'root'
    group 'root'
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

node_npm "async" do
    action :install
    notifies :restart, "service[dreadnot]"
end

deploy node[:dreadnot][:path] do
    repo "git@github.com:needle/dreadnot-stacks.git"
    symlinks.clear
    symlink_before_migrate.clear
    create_dirs_before_symlink.clear
    purge_before_symlink.clear
    ssh_wrapper '/opt/needle/shared/dreadnot_deploy_wrapper.sh'
    notifies :restart, "service[dreadnot]"
end

link ::File.join(node[:dreadnot][:path],"/stacks") do
    to ::File.join(node[:dreadnot][:path],"/current")
end

partners.each do |p|
  link ::File.join(node[:dreadnot][:path],"#{p}_assets.js") do
    to ::File.join(node[:dreadnot][:path],"stacks","assets.js")
  end
  link ::File.join(node[:dreadnot][:path],"stacks","#{p}_core.js") do
    to ::File.join(node[:dreadnot][:path],"stacks","core.js")
  end
end

runit_service "dreadnot"

if node.has_key?('ec2')
  include_recipe "aws"

  aws_resource_tag node['ec2']['instance_id'] do
    aws_access_key secrets['aws']['haystack']['access_key_id']
    aws_secret_access_key secrets['aws']['haystack']['secret_access_key']
    tags({'Name'=>"Dreadnot Deploy Server (#{node.chef_environment.capitalize})",
      'Environment'=>node.chef_environment})
  end

end