#!/bin/bash
source /tmp/prodstack/identity/identity_fun.sh
source /tmp/prodstack/openstack.rc
source /tmp/prodstack/admin.rc
source /tmp/prodstack/demo.rc 

# 3.2.1 - completed through ansible
# 3.2.2 - specify database configuration file
printf "Setting openstack config... \n"
set_openstack_config

# 3.2.3 - create identity user
printf "Creating identity user in mysql...\n"
create_identity_user

# 3.2.4 create database tables
printf "Creating database tables for keystone...\n"
create_database_tables

# 3.2.5 set authorization token
printf "Setting admin token: $ADMIN_TOKEN\n"| tee "/root/admin_token.txt"
set_authorization_token

# 3.2.6 create signing key
printf "Generating signing key...\n"
create_signing_key

printf "Checking for PURGE_EXPIRED_TOKENS...\n"
purge_expired_tokens

# 3.3.1 create admin user
printf "Creating admin user... \n"
create_admin_user

sleep 2

# create admin role
printf "Creating admin role... \n"
create_admin_role

sleep 2

# create tenant
printf "Creating admin tenant...\n"
create_admin_tenant

sleep 2

# link admin user role together
printf "Linking admin role with user role... \n"
link_admin_role

sleep 2

# link _member_ role
printf "Linking member role with admin role... \n"
link_member_role

sleep 2

#3.3.2 create normal "demo" user
printf "Creating \"demo\" user, role, and tenant... \n" 
create_demo_user

sleep 2

printf "Creating service tenant... \n"
create_service_tenant

sleep 2

# 3.4.1 create service entry for identity service
printf "Creating service entry for identity... \n"
create_identity_service

sleep 2


