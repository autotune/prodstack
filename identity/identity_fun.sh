#!/bin/bash
# functions for identity

function set_openstack_config() {

printf "$(date)" >  /tmp/prodstack/hello.tmp  
printf "$(openstack-config --set /etc/keystone/keystone.conf \
database connection mysql://keystone:$KEYSTONE_DBPASS@controller/keystone)"

} 

function create_identity_user() {

printf "$(mysql -e "CREATE DATABASE keystone;")"
printf "$(mysql -e "GRANT ALL ON keystone.* TO 'keystone'@'localhost' IDENTIFIED BY \"$KEYSTONE_DBPASS\";")"
printf "$(mysql -e "GRANT ALL ON keystone.* TO keystone@'%' IDENTIFIED BY \"$KEYSTONE_DBPASS\";")"
printf "$(mysql -e 'FLUSH PRIVILEGES;')"

}

function create_database_tables() {

printf "$(su -s /bin/sh -c "keystone-manage db_sync" keystone)"

}

function set_authorization_token() {

printf "$(openstack-config --set /etc/keystone/keystone.conf DEFAULT \
   admin_token $ADMIN_TOKEN)\n"

}

function create_signing_key() {

printf "$(keystone-manage pki_setup --keystone-user keystone --keystone-group keystone)"
printf "Changing /etc/keystone/ssl permissions..."
printf "$(chown -R keystone:keystone /etc/keystone/ssl && chmod -R o-rwx /etc/keystone/ssl)"

}

function purge_expired_tokens() {

if [[ $(grep "PURGE_EXPIRED_TOKENS" /tmp/prodstack/openstack.rc) == "PURGE_EXPIRED_TOKENS='YES'" ]]
then
  printf "Adding cron job to purge database tokens...\n"
  printf "$((crontab -l -u keystone 2>&1 | grep -q token_flush) || \
  printf '@hourly /usr/bin/keystone-manage token_flush >/var/log/keystone/keystone-tokenflush.log 2>&1' >> /var/spool/cron/keystone))"
fi

}

function create_admin_user() {

printf "$(keystone user-create --name=admin --pass=$ADMIN_PASS --email=$ADMIN_EMAIL)"

}

function create_admin_role() {

printf "$(keystone role-create --name=admin)"

}

function create_admin_tenant() {

printf "$(keystone tenant-create --name=admin --description="Admin Tenant")"

}

function link_admin_role() {

printf "$(keystone user-role-add --user=admin --tenant=admin --role=admin)"

}

function link_member_role() {

printf "$(keystone user-role-add --user=admin --role=_member_ --tenant=admin)"

}

function create_demo_user() {

printf "$(keystone user-create --name=demo --pass=$DEMO_PASS --email=$DEMO_EMAIL)"
sleep 2
printf "$(keystone tenant-create --name=demo --description="Demo Tenant")"
sleep 2
printf "$(keystone user-role-add --user=demo --role=_member_ --tenant=demo)"

}

function create_service_tenant() {

printf "$(keystone tenant-create --name=service --description="Service Tenant")"

}

function create_identity_service() {

printf "$(keystone service-create --name=keystone --type=identity \
  --description="OpenStack Identity")"

}

