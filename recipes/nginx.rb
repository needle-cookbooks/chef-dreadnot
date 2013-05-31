include_recipe 'needle-base::deploy'
include_recipe 'needle-base'
include_recipe 'nginx'
include_recipe 'dreadnot::default'

template "#{node['nginx']['dir']}/sites-available/dreadnot" do
  source "nginx.conf.erb"
  owner "root"
  group "root"
  mode 0644
  variables({:env_domain => Needle::DNS.domain_by_env(node.chef_environment)})
  notifies :restart, "service[nginx]"
end

%w{ 000-default default }.each do |defaultsite|
  nginx_site defaultsite do
    enable false
  end
end

nginx_site "dreadnot" do
  enable true
end
