# IDEA

- Sensu server with RabbitMQ password auth
  - authorize as host
- Sensu clients - autoscale group
  - authorize as a hostfactory

## 1. Getting started

Install:
- Install conjur 4.21.1-1 OsX prebuilt pkg, MIT license
  - FIX: package is unsigned, Conjur should fix
  - Update GEM_PATH to include their gems, with this `.bashrc` snippet:

        [ -h /usr/local/bin/conjur ] &&
          export GEM_PATH=/opt/conjur/embedded/lib/ruby/gems/2.1.0:$GEM_PATH

  - Update 2: Patched /usr/local/bin/conjur with these lines:

        ENV['GEM_PATH']='/opt/conjur/embedded/lib/ruby/gems/2.1.0'
        ENV['GEM_HOME']=''

conjur init:

    conjur init
    # enter hostname and accept defaults
    # creates /Users/pburkholder/conjur-chef.pem and
    # /Users/pburkholder/.conjurrc

Move pem in `~/.conjur/conjur-chef.pem` and update `.conjurrc` to use correct path

conjur bootstrap:

    conjur bootstrap
    # - enter admin as the username
    # - enter admin password
    # - add my username, 'pburkholder'
    #   - enter my password

conjur ui:

Install conjur-asset-ui-beta (2.0.0) with:
  bash
  unset GEM_HOME
  unset GEM_ROOT
  sudo /opt/conjur/embedded/bin/gem install  conjur-asset-ui-beta
  exit

Other:
- I'd like to update my dns so 'conjur.my.domain' is CNAME'd to the ec2 public DNS, but that causes cert mismatch errors.

## 2. Reproduce the conjur-kitchen demo with RabbitMQ

```
git clone https://github.com/conjurdemos/conjur-kitchen.git
cd conjur-kitchen
conjur variable create -v rabidmq_user webinar-example/rabbitmq/username
conjur variable create -v rabidmq_pass webinar-example/rabbitmq/password
conjur env check # passes because .conjurenv already in place

chef gem install kitchen-docker
boot2docker up
# Set the env vars that come out of boot2docker
export DOCKER_HOST=tcp://192.168.59.103:2376
export DOCKER_CERT_PATH=/Users/pburkholder/.boot2docker/certs/boot2docker-vm
export DOCKER_TLS_VERIFY=1

# Now do it
conjur env run -- kitchen converge
conjur env run -- kitchen verify # works
kitchen verify # also works!
```
## 3. Sensu Master in Test Kitchen

Next I built a sensu_master node with stock upstream cookbook, then customized to use conjur for the RabbitMQ secret. Start with Sean Porter's 'chef-monitor' cookbook from https://github.com/portertech/chef-monitor.git, then customize.  Getting the initial kitchen tests to pass takes some tweaking of the Ubuntu version (bump to 14.04) and the bats test needs to look for Uchiwa instead of sensu-dashboard.

That, done I started hacking it to use Conjur for secrets. You can see the cookbook at [https://github.com/pburkholder/chef-monitor/tree/pdb/conjur]

For conjur to work inside of the test-kitchen Vagrant instance, you need to set the env vars CONJUR_AUTHN_API_KEY and CONJUR_AUTHN_LOGIN for the host.  Those keys are the sensu master host identity, which is created like this:


```
conjur host create sensu_master
{
  "id": "sensu_master",
  "userid": "pburkholder",
  "created_at": "2015-04-27T18:36:52Z",
  "ownerid": "chef:user:pburkholder",
  "roleid": "chef:host:sensu_master",
  "resource_identifier": "chef:host:sensu_master",
  "api_key": "rs9j8s1m1gwz32k6jr6g2qve9911y5pdvq19spq721e1tjc729kbdy2"
}
```

Export the env vars: (ACTUALLY, DOING THIS SETS YOUR IDENTITY TO host/sensu_master)

```
export CONJUR_AUTHN_LOGIN='host/sensu_master'
export CONJUR_AUTHN_API_KEY='rs9j8s1m1gwz32k6jr6g2qve9911y5pdvq19spq721e1tjc729kbdy2'
```

and to the .kitchen.yml, add:

    conjur:
      identity:
    #        login: 'host/sensu_master'
    #        password: 'rs9j8s1m1gwz32k6jr6g2qve9911y5pdvq19spq721e1tjc729kbdy2'
        login: <%= ENV['CONJUR_AUTHN_LOGIN'] %>
        password: <%= ENV['CONJUR_AUTHN_API_KEY'] %>


That will create the `/etc/conjur.identity` file. This relies on you setting the ENV variables in your shell prior to kicking off TK.  Now to set the passwords themselves, you can take either of two approaches:

1. launch chef-client under the conjur environment, which presents a significant bootstrap ordering problem, or
2. use the conjur gem within Chef.

I'm opting to use the conjur within Ruby. To install, use the 'chef' gem and install conjur-api and conjur-cli:

    export PATH=/opt/chef/embedded/bin:$PATH
    sudo gem install conjur-api
    sudo gem install conjur-cli

How to get to the value of the 'test/username' variable, starting from `sudo pry`:

    require 'conjur/cli'
    Conjur::Config.load
    Conjur::Config.apply
    conjur = Conjur::Authn.connect nil, noask: true
    v = conjur.variable 'test/username'
    v.value

So this means using the env vars to set the /etc/identity, and then the conjur gem to fetch. See recipe/conjurized.

```
for var in user password; do
  conjur variable create monitor/rabbitmq/$var ${var}_from_conjur
  conjur resource permit variable:monitor/rabbitmq/$var host:sensu_master execute
done
```

And that completely works -- although the secrets are exposed as file diffs.

Now that I've done this iteratively, let's start from scratch.

Drop the conjur::client install recipe since it's not compile time, use chef_gem instead. We may get into build_essentials hell, though.

Also, we need to set the CONJUR_AUTHN_* env vars, so we'll use `.conjurenv`


```
conjur_authn_login: !var monitor/sensu_master/conjur_login
conjur_authn_api_key: !var monitor/sensu_master/conjur_api_key
```

And add those as variables:

```
conjur variable create monitor/sensu_master/conjur_login "host/sensu_master"
conjur variable create monitor/sensu_master/conjur_api_key  'rs9j8s1m1gwz32k6jr6g2qve9911y5pdvq19spq721e1tjc729kbdy2'
```

Now run:
```
conjur env check --  make sure our secrets are available.
conjur env run -- kitchen converge conjur # to converge the node, with secret values passed in at runtime.
conjur env run -- kitchen verify conjur # to ensure default passwords have been overwritten.
```


To get this run, I set the `remote_file` and `package` resources for Conjur client to `run_action(:create)` and `run_action(:install)`, respectively. And to load the Gems:

```
Gem.path << "/opt/conjur/embedded/lib/ruby/gems/2.1.0"
Gem::Specification.reset
```

To recap:
- We store the RabbitMQ user and password in variables, 'monitor/rabbitmq/user' and 'monitor/rabbitmq/password'
- We've created a host, sensu_master, and given it 'execute' privileges on the varia
- We run test-kitchen within `conjur env` so the values for CONJUR_AUTHN_LOGIN and CONJUR_AUTH_API_KEY get populated without being exposed
  - That uses the variables `monitor/sensu_master/conjur_login` and `monitor/sensu_master/conjur_api_key`, which are referenced from the `.conjurenv` file
  - test-kitchen has those values passed as attributes in `.kitchen.yml`:

        conjur:
          identity:
            login: <%= ENV['CONJUR_AUTHN_LOGIN'] %>
            password: <%= ENV['CONJUR_AUTHN_API_KEY'] %>

- When the test-kitchen node converges, those values will populate `/etc/conjur.identity` during the compile phase
  - The compile phase will also create '/etc/conjur.conf' and populate '/etc/conjur-chef.pem' with the SSL cert of our server
- During compile phase we'll also want to populate the values for sensu.rabbitmq.user etc.
  - Fetch the .deb remote .deb file and install the .deb package during compile time.
  - Include the installed gems in the GEM_PATH with:

        Gem.path << "/opt/conjur/embedded/lib/ruby/gems/2.1.0"
        Gem::Specification.reset

  - Then get the values we need:

        conjur = Conjur::Authn.connect nil, noask: true
        user_var = conjur.variable 'monitor/rabbitmq/user'
        node.default['sensu']['rabbitmq']['user'] = user_var.value

## 4. sensu_master in EC2

- We'll need a security group with correct ingress/egress. The default security group for the default VPC seems to allow inter-node communication

- For node self-configuration, using a USER_DATA script which is in cookbooks/sensu_master/recipes/aws.rb.

- Create data bag on chef server so the server has SSL certificates:

    knife data bag create sensu
    knife data bag from file sensu test/integration/data_bags/sensu/ssl.json

- Make attribute for `node[monitor][master_address]` which comes from, for now, an environment
  - Ideally, the sensu_master would use `route53` to set its own DNS, but that requires `fog`, and hence `nokogiri`, and that's just too painful. So I've manually set the CNAME for sensu_master.cheffian.com
  - To set the attribute for the sensu_master, I have stuck that in a 'conjur' chef_environment:

    knife environment from file conjur.json

- Now - I have cookbooks loaded, should be able to

    conjur env run -- chef-client -z sensu_master/recipes/aws.rb

- That works as tagged "sensu_master/0.1.0"

- To use, ssh as below then use FoxyProxy socks5 dynamic proxy through localhost:3128 to reach http://sensu_master.cheffian.com:3000.  user: admin, password: supersecret

    ssh -D 3128 ubuntu@sensu_master.cheffian.com

## 5 sensu_client in TK

We'll start with test-kitchen-ec2 and crib off the 'conjur' cookbook for the .kitchen.yml

Once we get that to work with vanilla attributes, e.g.:

    default["sensu"]["rabbitmq"]["user"]= "user_from_conjur"
    default["sensu"]["rabbitmq"]["password"]= "password_from_conjur"

then we work with hostfactory

### Hostfactory

Need a group:

    conjur group create demo

    {
      "id": "demo",
      "userid": "pburkholder",
      "ownerid": "chef:user:pburkholder",
      "roleid": "chef:group:demo",
      "resource_identifier": "chef:group:demo"
    }

Create a layer

    conjur layer create --as-group demo sensu/generic
    {
      "id": "sensu/generic",
      "userid": "pburkholder",
      "ownerid": "chef:user:pburkholder",
      "roleid": "chef:layer:sensu/generic",
      "resource_identifier": "chef:layer:sensu/generic",
      "hosts": [ ]
    }

Install the hostfactory plugin. To enable this, update `~/.conjurrc` with

    plugins:
    - ui-beta
    - host-factory

And install with:

    bash
    unset GEM_HOME
    unset GEM_ROOT
    sudo /opt/conjur/embedded/bin/gem install conjur-asset-host-factory
    exit

Now that that is installed, create a host factory for the sensu/generic layer

    conjur hostfactory create --as-group demo -l sensu/generic sensu/generic


Then we get this output with the above command:

    {
      "id": "sensu/generic",
      "layers": [
        "sensu/generic"
      ],
      "roleid": "chef:group:demo",
      "resourceid": "chef:host_factory:sensu/generic",
      "tokens": [

      ],
      "deputy_api_key": "3ncr3hf236z8sf1sf10w3yt48tj3q9tpmw8685zf3gkr8ns3q7qhc7"
    }


Since the hostfactory is going to be creating hosts in the layer, sensu/generic, we want to grant the  execute privileges on the sensu variables to that layer:

    conjur resource permit variable:monitor/rabbitmq/user layer:sensu/generic execute
    conjur resource permit variable:monitor/rabbitmq/password layer:sensu/generic execute


*About ownership and roles.*

We'll think backwards about this.
  - We want hosts to read variables, so we grant them 'execute' privileges
  - The hosts don't exist yet, but they'll be in the layer sensu/generic, so we grant that layer the execute privilege with:
      conjur resource permit variable:monitor/rabbitmq/user layer:sensu/generic execute
  - Who gets to administrate that layer and the hostfactory? Members of the demo group, which is why we used `--as-group demo` with the 'conjur layer create' and `conjur hostfactory create`
  - Now create a token which expires in 6 hours. This is executed by you on the workstation, you're a member of the 'demo' so you have the privileges to create new tokens, then tokens are used to create new hosts in the sensu/generic layer, and that layer has already been granted 'execute' on the variables:

```
    conjur hostfactory tokens create --duration-hours=6 sensu/generic

    [
      {
        "token": "26e3zzy2ybqzq16vgb70hnxc383kk1ppa3ny3q9g30pb5b3911t5h",
        "expiration": "2015-04-30T22:33:31+00:00"
      }
    ]
```

*Testing*

To test on the TK node, added 'conjur.rb' to sensu_client/{recipes,attributes}, and on the node:

    # as root

    # Install the hostfactory plugin:
    /opt/conjur/embedded/bin/gem install conjur-asset-host-factory

    # Enable the plugin:
    cat <<END>>/etc/conjur.conf
    plugins: [ host-factory ]
    END

    # Use the hostfactory token to create a host:
    conjur hostfactory hosts create 26e3zzy2ybqzq16vgb70hnxc383kk1ppa3ny3q9g30pb5b3911t5h ec2/i-9e64bf48
    #  {
    #    "id": "ec2/i-9e64bf48",
    #    "userid": "deputy/sensu/generic",
    #    "created_at": "2015-04-30T20:23:08Z",
    #    "ownerid": "chef:group:demo",
    #    "roleid": "chef:host:ec2/i-9e64bf48",
    #    "resource_identifier": "chef:host:ec2/i-9e64bf48",
    #    "api_key": "2ndsa2h3cpgj5p2n7cmbx1q0vxq51shqatx2cdckyw2ds25zpgx71eh"
    #  }

    # Now write these to /etc/conjur.identity
    cat <<END>/etc/conjur.identity
    machine https://ec2-54-90-25-181.compute-1.amazonaws.com/api/authn
    login host/ec2/i-9e64bf48
    password 2ndsa2h3cpgj5p2n7cmbx1q0vxq51shqatx2cdckyw2ds25zpgx71eh
    END

    # Fix perms
    chmod 0400 /etc/conjur.identity

    # Test
    conjur variable value monitor/rabbitmq/user

     # Fini


### Fixing broken permissions:

The first time I did this, I ran the following w/o the `--as-group demo` argument

    conjur layer create sensu/generic

Fixed this with Kevin Gilpin's help:

    # give ownership on the layer to chef:group:demo
    conjur resource give chef:layer:sensu/generic chef:group:demo

    # grant group:demo the admin role (`-a`) over layer:sensu/generic
    conjur role grant_to -a layer:sensu/generic group:demo

    # review the state of permissions:
    conjur layer show sensu/generic
    conjur resource show layer:sensu/generic
    conjur role memberships group:demo

I also did these commands when things were borked, I have no idea if they were needed or not:

    conjur layer hosts permit sensu/generic group:demo update
    conjur layer hosts permit sensu/generic group:demo execute


## How to get rolling with Conjur after two weeks away

First, am I logged in?  Tries the following commands:

```
conjur authn whoami
conjur variable list
conjur variable show monitor/rabbitmq/user
```

And is my sensu_master still running?

```
aws ec2 describe-instances --filters Name=key-name,Values="pburkholder-one"
```

It is.  And it' still at `sensu_master.cheffian.com`. Conjur still works, but can't get variable:

```
$ conjur authn whoami
{"account":"chef","username":"host/sensu_master"}

$ conjur variable show monitor/rabbitmq/password
error: 403 Forbidden
```

Ah, but it can fetch the value:

```
$ conjur variable value monitor/rabbitmq/password
Boom!
```


## Continuing with autoscale

In `sensu_client/recipes/aws.rb` I'll update the userdata to include the hostfactory token and to get it written at boot time.

I'll also just spin up a single client.

```
conjur hostfactory tokens create --duration-hours=6 sensu/generic
```

Next:
- update `sensu_client/recipes/aws.rb` to drop the hostfactory token onto box from userdata
- update `sensu_client/recipes/conjur.rb` to
  - install the netrc gem
  - create the conjur group
  - install the conjur-asset-host-factory gem into the conjur install
  - use a ruby_block to exec the host-factory call and write response to conjur.identity
