require 'chef/provisioning/aws_driver'
run_list                 = %q({"run_list":["recipe[apt]","recipe[monitor::conjurized]"]})
chef_server_url          = 'https://api.opscode.com/organizations/pdbchef'
validation_client_name   = 'pdbchef-validator'
environment              = 'conjur'
node_name                = 'sensu_master'
machine                  = 'https://ec2-54-90-25-181.compute-1.amazonaws.com/api/authn'
login                    = ENV['CONJUR_AUTHN_LOGIN']
password                 = ENV['CONJUR_AUTHN_API_KEY']

raise "Need login and password from conjur env" if ( login.nil? || password.nil? )


user_data = <<END_SCRIPT
#!/bin/bash

# Install chef-client
curl -L https://www.opscode.com/chef/install.sh | bash /dev/stdin -v 12.3.0

# Set up validation.pem
mkdir /etc/chef
cat <<END_PEM>/etc/chef/validation.pem
-----BEGIN RSA PRIVATE KEY-----
MIIEpQIBAAKCAQEAxEzTfvpL3rcVV3DDe0aJvaL2290diUaX6NRJglxHrn0WNaUQ
+xsNTmWgt86O3AbqxZ36tLLaOsa+2FJY7pnvjn+q5+aaxzHcS+6Oa6xemHgaFV9L
ItVMd4aCNCkX83J3WSEQVhBhCP0O24SQkLTv4jXTItXKZOss5T2wlnxteL6dOBbB
NfiCGtyUmqtiRMpMx3vaPRQ5jj+bYNo7D1jhn3FHtOieTGMm+LiNm2DV41WS8gOK
vhx6nhytS53s+dCdXUHKTPIZAMclrIl8GRhx8/peW9zvcPlISDScT5M3en0zdkbk
fJldXexUjdM3qZKIr+T92p40QXZD+7+R0FOwnQIDAQABAoIBAGJrClbNcyCUtnSC
qt+xu/mCLTaKo/ZhmGQ5mylqzt2jBXGb8umS5Jb7yRqey21xYl/2Fu5mBZgWcTTQ
BJqMP1k4lR1ztwJL82F2l51QbJUREjLI9kjenFoI7Fruh32dVE0xkJk12RDCn6Jb
0oda0DKgPd1nRvRWHMpKpbCtbc1tEsiTl/l/YDrL6NBPjorq8yTT+Wi8kcMasZ8l
EW1aYXBtZfb09ZU0oeolplxECQpTli0pXXx+X6G0QbPqq8g2Ppr2Zt0uoMrv7sMP
kSFGr8aCkObtiWszQond3UOUqgVUicHmeNu+L4AHXGc6zbqP4SopvoGeMmpjbq+K
EgzFBQECgYEA8Yg5JjIZpg03tU3dtsbiRrTEFBUVOsAY2uEDzXJY1ubpI0vlX9j0
oETiJYij+33Lc0tcQZ2VtuwuaNj6VgmsWNNPnto63XBg1ZycWVpCTGzJjXj9yEKj
fjiigSAIJW2EARgaKix5Lr9owI24AZexXzMN+ezegxR6re8uswe8fuECgYEA0A79
9yjmH33hrVOAOD39+oNKYpiT4R+shP4AVwAOxsawgz2f5zhvk7kfj58ZXrvEPcf4
xoih2Gc3BnndwqOl/6/xcE8hRQ6YIaKVXBTWC38Z0jrwWmTaGY1szyYd16YMcqgY
SynZAi1Vb5SIb1ren9GNoi+/4PozmITiwgchFT0CgYEAigfMiSyGheP12zIVq9e7
BqdVixiFWl7flW6UaruXU7EAuUAtZHorStAy4TpWZGn+c/Q0U/dH0RLmbtrZLYQ3
r0eLr/+NNnF7lXf7zgCL9PsSsDvd5K1Ym9Cn5d01apZMowdwJHvoATQ4HBqhdp+H
KR2XNiYM/6Ibff07leqs6WECgYEAjCB8xbkC/FTA6QajBb4iz1UbhToz5tx5Sfz0
Z6P/T7tD6LBZgNYOt9RnwEgsQxR9QArtr3EYZ/JkKfVr+QpU49cw6i4xPxxsM8MX
izPxUT7iOig99vOTvL/2d7G5SaNpINO7wOvHX2L+9q54EV+HLuZo2MIGHlUE6QUe
4AUDMBUCgYEAnl/OvZpVlzvccwsEeNAwNCZ/37b7nnrdU+lmnbrnLxBPv8K9/QBo
Wlx2wz/zMif1ChkOqktzVmojQHw7bMz9H0qmbWQiEkV9/ZpYT5YQc5UlxGaZRZF7
tXBDJE/kkZ3+/ucnTdi0i5aNQt014WDZTUzayxcU1toDv1eCLP6CDC8=
-----END RSA PRIVATE KEY-----
END_PEM

# Set up client.rb

cat <<END_CLIENT>/etc/chef/client.rb
log_level        :auto
log_location     "/tmp/first-chef-client-run.log"
chef_server_url  "#{chef_server_url}"
validation_client_name  "#{validation_client_name}"
environment      "#{environment}"
END_CLIENT

instance_id=$(curl -s http://169.254.169.254/latest/meta-data/instance-id)
node_name=$(printf "#{node_name}-%s\n" $instance_id)

cat <<END_NN>>/etc/chef/client.rb
node_name        "$node_name"
END_NN

# Set first boot JSON
cat <<END_JSON>/etc/chef/run_list.json
#{run_list}
END_JSON

# Create /etc/conjur.identity
cat <<END_CONJUR>/etc/conjur.identity
machine #{machine}
    login #{login}
    password #{password}
END_CONJUR
chmod 0400 /etc/conjur.identity

# Give Ohai a hint about EC2
mkdir -p /etc/chef/ohai/hints
touch /etc/chef/ohai/hints/ec2.json

# Kick off chef run
/usr/bin/chef-client -j /etc/chef/run_list.json

# Fini
exit
END_SCRIPT


with_driver 'aws::us-east-1' do
  aws_launch_configuration 'peterb-sensu-master' do
    image 'ami-d85e75b0'  # Trusty
    instance_type 'm3.medium'
    options({
      security_groups: ['sg-2ee7694b'],
      key_pair: 'pburkholder-one',
      user_data: user_data
    })
  end

  aws_auto_scaling_group 'peterb-sensu-master' do
    desired_capacity 1
    min_size 1
    max_size 1
    launch_configuration 'peterb-sensu-master'
    availability_zones ['us-east-1c']
  end
end
