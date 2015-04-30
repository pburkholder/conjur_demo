#
# Cookbook Name:: sensu_client
# Recipe:: default
#
# Copyright (c) 2015 The Authors, All Rights Reserved.


include_recipe "sensu_client::conjur"

Gem.path << "/opt/conjur/embedded/lib/ruby/gems/2.1.0"
Gem::Specification.reset

include_recipe "sensu::default"

sensu_client node.name do
  address node["ipaddress"]
  subscriptions node["roles"] + ["all"]
end

include_recipe "sensu::client_service"
