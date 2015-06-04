# DEMO

### Major points to make

- 

----

## Goal

- Get a bunch of Sensu Clients up
- ssh -D sensu_master
  - http://sensu_master.cheffian.com:3000/#/clients
  - admin:supersecret

----


## Set up the autoscale group

```
export HOST_FACTORY=`conjur hostfactory tokens create --duration-hours=1 sensu/generic | jsonfield 0.token`

echo $HOST_FACTORY

chef-client -z cookbooks/sensu_client/recipes/aws.rb
```

----

## Who is Conjur?

https://developer.conjur.net/

----

## Getting set up as me:

```
conjur authn login
conjur authn whoami
```

----

## Look at the internals

```
more ~/.conjurrc
conjur ui
```

----

## Let's see the variables

```
conjur variable value monitor/rabbitmq/user
conjur variable value monitor/rabbitmq/password
```

----

## Grant a Layer access to those variables.

```
# conjur group create demo
# conjur layer create --as-group demo sensu/generic
# conjur hostfactory create --as-group demo -l sensu/generic sensu/generic
```

----

## Set up the autoscale group

```
export HOST_FACTORY=`conjur hostfactory tokens create --duration-hours=1 sensu/generic | jsonfield 0.token`

echo $HOST_FACTORY

chef-client -z cookbooks/sensu_client/recipes/aws.rb
```

----

## Look at recipe

<br>

----

## Review permissions

```
conjur resource show layer:sensu/generic
conjur layer show sensu/generic
conjur hostfactory list
```

----


## thoughts on Chef Vault

- No clear-txt secrets in version control
- audit trail is in conjur instead of SCM
- no role impersonation
- no databag write lock issues
- Easier to use?
