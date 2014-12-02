#!/bin/bash
source /tmp/prodstack/openstack.rc
source /tmp/prodstack/admin.rc
source /tmp/prodstack/demo.rc 

# 3.2.1 - completed through ansible
# 3.2.2 - specify database configuration file
printf "Setting openstack config... \n"
printf "$(openstack-config --set /etc/keystone/keystone.conf \
database connection mysql://keystone:$KEYSTONE_DBPASS@controller/keystone)"

# 3.2.3 - create identity user
printf "Creating identity user in mysql...\n"
printf "$(mysql -e "CREATE DATABASE keystone;")"
printf "$(mysql -e "GRANT ALL ON keystone.* TO 'keystone'@'localhost' IDENTIFIED BY \"$KEYSTONE_DBPASS\";")"
printf "$(mysql -e "GRANT ALL ON keystone.* TO keystone@'%' IDENTIFIED BY \"$KEYSTONE_DBPASS\";")"
printf "$(mysql -e 'FLUSH PRIVILEGES;')"

# 3.2.4 create database tables
printf "Creating database tables for keystone...\n"
printf "$(su -s /bin/sh -c "keystone-manage db_sync" keystone)"


# 3.2.5 define authorization token
printf "Setting admin token: $ADMIN_TOKEN\n"| tee "/root/admin_token.txt"
printf "$(openstack-config --set /etc/keystone/keystone.conf DEFAULT \
   admin_token $ADMIN_TOKEN)\n"

# 3.2.6 create signing key
printf "Generating signing key...\n"
printf "$(keystone-manage pki_setup --keystone-user keystone --keystone-group keystone)"
printf "Changing /etc/keystone/ssl permissions..."
printf "$(chown -R keystone:keystone /etc/keystone/ssl && chmod -R o-rwx /etc/keystone/ssl)"

printf "Checking for PURGE_EXPIRED_TOKENS...\n"

if [[ $(grep "PURGE_EXPIRED_TOKENS" /tmp/prodstack/openstack.rc) == "PURGE_EXPIRED_TOKENS='YES'" ]]
then
  printf "Adding cron job to purge database tokens...\n"
  printf "$((crontab -l -u keystone 2>&1 | grep -q token_flush) || \
  printf '@hourly /usr/bin/keystone-manage token_flush >/var/log/keystone/keystone-tokenflush.log 2>&1' >> /var/spool/cron/keystone))"
fi

# 3.3.1 create admin user
printf "$(keystone user-create --name=admin --pass=$ADMIN_PASS --email=$ADMIN_EMAIL)"

sleep 2

# create role
printf "$(keystone role-create --name=admin)"

sleep 2

# create tenant
printf "$(keystone tenant-create --name=admin --description="Admin Tenant")"

sleep 2

# link admin user role together
printf "$(keystone user-role-add --user=admin --tenant=admin --role=admin)"

sleep 2

# link _member_ role
printf "$(keystone user-role-add --user=admin --role=_member_ --tenant=admin)"

sleep 2

#3.3.2 create normal "demo" user
printf "$(keystone user-create --name=demo --pass=$DEMO_PASS --email=$DEMO_EMAIL)"

sleep 2

printf "$(keystone tenant-create --name=demo --description="Demo Tenant")"

sleep 2

printf "$(keystone user-role-add --user=demo --role=_member_ --tenant=demo)"

sleep 2

printf "$(keystone tenant-create --name=service --description="Service Tenant")"


# 3.4.1 create service entry for identity service
printf "$(keystone service-create --name=keystone --type=identity \
  --description="OpenStack Identity")"

sleep 2


