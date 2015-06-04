#
# Cookbook Name:: sensu_client
# Recipe:: default
#
# Copyright (c) 2015 The Authors, All Rights Reserved.


include_recipe "sensu_client::conjur"

Gem.path << "/opt/conjur/embedded/lib/ruby/gems/2.1.0"
Gem::Specification.reset


# Now get passwords from conjur and pass to RabbitMQ:
# require 'pry'
# binding.pry
require 'conjur/cli'
Conjur::Config.load
Conjur::Config.apply
conjur = Conjur::Authn.connect nil, noask: true
user_var = conjur.variable 'monitor/rabbitmq/user'
password_var = conjur.variable 'monitor/rabbitmq/password'
node.default['sensu']['rabbitmq']['user'] = user_var.value
node.default['sensu']['rabbitmq']['password'] = password_var.value

include_recipe "sensu::default"

sensu_client node.name do
  address node["ipaddress"]
  subscriptions node["roles"] + ["all"]
end

include_recipe "sensu::client_service"
