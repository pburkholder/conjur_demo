#
# Cookbook Name:: sensu_client
# Recipe:: default
#
# Copyright (c) 2015 The Authors, All Rights Reserved.

include_recipe "sensu::default"

sensu_client node.name do
  address node["ipaddress"]
  subscriptions node["roles"] + ["all"]
end

include_recipe "sensu::client_service"
