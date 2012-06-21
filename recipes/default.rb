include_recipe "apt"
include_recipe "node::apt"
include_recipe "base::deploy"
include_recipe "deploy_wrapper"

data_bag_key = Chef::EncryptedDataBagItem.load_secret(node['data_bag_key'])
secrets = Chef::EncryptedDataBagItem.load("secrets", node.chef_environment, data_bag_key)

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
    variables( :dreadnot => @node[:dreadnot] )
end

node_npm "dreadnot" do
    action :install
end

runit_service "dreadnot"

deploy "/opt/needle/dreadnot/" do
    repository "dreadnot-stacks"
    revision assets_revision
    symlinks.clear
    symlink_before_migrate.clear
    create_dirs_before_symlink.clear
    purge_before_symlink.clear
    ssh_wrapper '/opt/needle/shared/dreadnot_deploy_wrapper.sh'
end

