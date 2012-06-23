include_recipe "apt"
include_recipe "node::apt"
include_recipe "base::deploy"
include_recipe "deploy_wrapper"
include_recipe "runit"

data_bag_key = Chef::EncryptedDataBagItem.load_secret(node['data_bag_key'])
secrets = Chef::EncryptedDataBagItem.load("secrets", node.chef_environment, data_bag_key)

directory '/opt/needle/shared' do
  owner 'root'
  group 'root'
  mode 0755
end

directory '/opt/needle/dreadnot' do
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

template '/opt/needle/dreadnot/local_settings.js' do
    source 'local_settings.js.erb'
    mode 0750
    owner 'root'
    group 'root'
    variables( :dreadnot => node[:dreadnot], :secrets => secrets )
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

node_npm "https://github.com/needle/dreadnot/tarball/master" do
    action :install
end

node_npm "async" do
    action :install
end

runit_service "dreadnot"

deploy "/opt/needle/dreadnot" do
    repo "git@github.com:needle/dreadnot-stacks.git"
    symlinks.clear
    symlink_before_migrate.clear
    create_dirs_before_symlink.clear
    purge_before_symlink.clear
    ssh_wrapper '/opt/needle/shared/dreadnot_deploy_wrapper.sh'
end

link "/opt/needle/dreadnot/stacks" do
    to "/opt/needle/dreadnot/current"
end
