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


Other:
- I'd like to update my dns so 'conjur.my.domain' is CNAME'd to the ec2 public DNS, but that causes cert mismatch errors.

## 2. Use conjur for my own RabbitMQ demo

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
