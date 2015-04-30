
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
include_recipe "conjur::conjurrc"

# Install netrc gem, create group 'conjur' and
# write the /etc/conjur.identity file using netrc
# gem from helper method
# include_recipe "conjur::identity"   # Arguably should be first recipe here.
