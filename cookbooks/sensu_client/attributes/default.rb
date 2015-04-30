default["sensu"]["use_embedded_ruby"] = true
default["sensu"]["version"] = "0.14.0-1"

# master_address = node.default['monitor']['master_address']

default["sensu"]["rabbitmq"]["host"] = "sensu_master.cheffian.com"
default["sensu"]["redis"]["host"] ="sensu_master.cheffian.com"
default["sensu"]["api"]["host"] = "sensu_master.cheffian.com"

default["sensu"]["rabbitmq"]["user"]= "user_from_conjur"
default["sensu"]["rabbitmq"]["password"]= "password_from_conjur"
