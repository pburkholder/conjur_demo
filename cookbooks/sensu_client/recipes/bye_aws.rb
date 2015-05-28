require 'chef/provisioning/aws_driver'
run_list                 = %q({"run_list":["recipe[apt]","recipe[sensu_client]"]})
chef_server_url          = 'https://api.opscode.com/organizations/pdbchef'
validation_client_name   = 'pdbchef-validator'
environment              = 'conjur'
node_name                = 'sensu_client' # instance name gets appended

example='autoscale'

with_driver 'aws::us-east-1' do
  if example == 'autoscale'

    aws_auto_scaling_group 'peterb-sensu-client' do
      action :destroy
      desired_capacity 1
      min_size 1
      max_size 22
      launch_configuration 'peterb-sensu-client'
      availability_zones ['us-east-1c']
    end

    aws_launch_configuration 'peterb-sensu-client' do
      action :destroy
      image 'ami-dc5e75b4'  # Trusty
      instance_type 't2.micro'
      options({
        security_groups: ['sg-2ee7694b'],
        key_pair: 'pburkholder-one',
      })
    end
  else
    machine 'sensu_client' do
      action :destroy

      add_machine_options bootstrap_options: {
        instance_type: 't2.micro',
        image_id: 'ami-dc5e75b4',
        security_group_ids: ['sg-2ee7694b' ],
        key_name: 'pburkholder-one',
      }
    end
  end # if autoscale
end
