maintainer  "Needle Ops"
maintainer_email "ops@needle.com"
description "Deploys and configures Dreadnot from Rackspace"
license "Apache 2.0"
version "0.0.1"

%w{ apt base deploy_wrapper node runit aws }.each do |cb|
  depends cb
end
