maintainer  "Needle Ops"
maintainer_email "ops@needle.com"
description "Deploys and configures Dreadnot from Rackspace"
license "Apache 2.0"
version "0.1.2"

%w{ apt deploy_wrapper node runit aws secrets needle-base sysctl }.each do |cb|
  depends cb
end

depends "discovery", "~> 0.2.1"

