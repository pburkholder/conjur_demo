#
# Cookbook Name:: sensu_client
# Recipe:: default
#
# Copyright (c) 2015 The Authors, All Rights Reserved.

include_recipe "sensu::default"
include_recipe "sensu::client_service"
