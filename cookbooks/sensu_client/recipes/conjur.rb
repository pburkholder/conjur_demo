
client_version = node['conjur']['client']['version']
file_name = "conjur-#{client_version}.deb"
target_path = File.join(Chef::Config[:file_cache_path], file_name)

remote_file target_path do
  source "https://s3.amazonaws.com/conjur-releases/omnibus/conjur_#{client_version}_amd64.deb"
end.run_action(:create)

dpkg_package "conjur" do
  source target_path
end.run_action(:install)

Gem.path << "/opt/conjur/embedded/lib/ruby/gems/2.1.0"
Gem::Specification.reset


# Write  /etc/conjur.conf and /etc/conjur*pem:
# Root ownership, presumably
# root cert is from ../attributes/default.rb
include_recipe "conjur::conjurrc"


# Install netrc gem, create group 'conjur' and
# write the /etc/conjur.identity file using netrc
# gem from helper method

chef_gem 'netrc' do
  compile_time true if Chef::Resource::ChefGem.method_defined?(:compile_time)
end

group 'conjur' do
  append true
end.run_action(:create)

#
# Here's the real stuff
#

gem_package 'conjur-asset-host-factory' do
  gem_binary '/opt/conjur/embedded/bin/gem'
end.run_action(:install)

ruby_block "generate conjur identity" do
  not_if  { ::File::exists?('/etc/conjur.identity') }
  only_if { ::File.exists?('/etc/conjur_hostfactory_token') }
  block do
    require 'json'
    hostfactory_token = ::File.read('/etc/conjur_hostfactory_token').chomp
    conjur_json = %x(
      /usr/local/bin/conjur hostfactory hosts create #{hostfactory_token} #{node.name}
    )
    conjur_response = JSON.parse(conjur_json)
    conjur_identity = <<END_ID
machine   #{node['conjur']['configuration']['appliance_url']}/authn
login     host/#{node.name}
password  #{conjur_response['api_key']}
END_ID
    ::File.open('/etc/conjur.identity', 'w') { |f| f.write(conjur_identity)}
    ::File.unlink('/etc/conjur_hostfactory_token')
  end
end.run_action(:create)
