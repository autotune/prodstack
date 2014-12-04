#!/bin/bash
DIR=/tmp/prodstack
ETH1="$(ifconfig eth1|grep "inet addr"|cut -d ":" -f2|awk '{print $1}')"

printf "This script will install all required services, checking success of verify.sh... \n"

sleep 1

# everything is relative to current directory until playbook runs and copies to /tmp/prodstack
if [[ $(grep "STAGE 2" ./status.tmp) ]]
then
  printf "Install will continue... \n\n"
  rm -fr $DIR
else
  printf "Something went wrong with verification, re-run verify.sh and fix issues to continue \n"
  printf "$(cat ./status.tmp)"
  exit 1
fi

printf "This script will auto-generate a pass and use default admin username unless the default openstack.rc is removed. Pass will be shown once generated. \n\n"

sleep 2 

printf "Setting enviornment variables for identity[1/10]... \n" 

printf "$(sed -i s/bind-address=/bind-address=$ETH1/g ./my.cnf)"

if [[ "$(cat ./openstack.rc|grep "KEYSTONE_DBPASS")" == *"CHANGE_ME"* ]]
then
  printf "Enter keystone database pass: "
  read KEYSTONE_DBPASS
  printf "$(sed -i "s/KEYSTONE_DBPASS=\"CHANGE_ME\"/KEYSTONE_DBPASS="\"$KEYSTONE_DBPASS\""/g" ./openstack.rc)"
  source "./openstack.rc"
  printf "KEYSTONE_DBPASS is $KEYSTONE_DBPASS"
 
else 
  source "./openstack.rc"
  printf "KEYSTONE_DBPASS is $KEYSTONE_DBPASS"
fi

sleep 2

if [[ "$(cat ./openstack.rc|grep "ADMIN_PASS")" == *"CHANGE_ME"* ]]
then
  printf "Enter admin pass: "
  read ADMIN_PASS
  printf "$(sed -i "s/ADMIN_PASS=\"CHANGE_ME\"/ADMIN_PASS="\"$ADMIN_PASS\""/g" ./openstack.rc)"
else 
  source "./openstack.rc"
  printf "ADMIN_PASS is $ADMIN_PASS"
fi

if [[ "$(cat ./openstack.rc|grep "ADMIN_EMAIL")" == *"CHANGE_ME"* ]]
then
  printf "Enter admin email: "
  read ADMIN_EMAIL
  printf "$(sed -i "s/ADMIN_EMAIL=\"CHANGE_ME\"/ADMIN_EMAIL="\"$ADMIN_EMAIL\""/g" ./openstack.rc)"
else
  source "./openstack.rc"
  printf "Admin email is $ADMIN_EMAIL"
fi  


if [[ "$(grep "DEMO_PASS" ./demo.rc)" == *"GENERATED"* ]]
then
  DEMO_PASS=$(openssl rand -hex 10)
  printf "$(sed -i "s/DEMO_PASS=\"GENERATED\"/DEMO_PASS="\"$DEMO_PASS\""/g" ./demo.rc)"
else
  source "./demo.rc"
  printf "demo pass is $DEMO_PASS"
fi

if [[ "$(grep "GLANCE_DBPASS" ./openstack.rc)" == *"CHANGE_ME"* ]]
then
  printf "Enter glance pass: "
  read GLANCE_DBPASS
  printf "$(sed -i "s/GLANCE_DBPASS=\"CHANGE_ME\"/GLANCE_DBPASS="\"$GLANCE_DBPASS\""/g" ./openstack.rc)"
else
  source "./openstack.rc"
  printf "glance dbpass is $GLANCE_DBPASS"
fi

# end of openstack.rc substitution
source "./openstack.rc"
source "./admin.rc"
source "./demo.rc"

# create initial files first
if [[ ! -e "/$USER/.my.cnf" ]]
then
  printf "" > "/$USER/.my.cnf"
fi

sleep 2 

# have to run through expect as ansible doesn't like expect in bash scripts

# clean this up later
printf "Copying mysql_staging.expect to mysql.expect... \n"
printf "$(/bin/cp -f "./mysql_staging.expect" "./mysql.expect")"

printf "Replacing KEYSTONE_DBPASS in mysql_staging.expect...\n"
sed -i "s/KEYSTONE_DBPASS/$KEYSTONE_DBPASS/g" "./mysql.expect" 

# clean this up later
printf "Copying ./.my_staging.cnf to ./.my.cnf... \n"
printf "$(/bin/cp -f "./.my_staging.cnf" "./.my.cnf") \n"

printf "Replacing KEYSTONE_DBPASS in ./.my.cnf... \n"
sed -i "s/pass=/pass="$KEYSTONE_DBPASS"/g" "./.my.cnf"

printf "Moving over to /root/.my.cnf... \n"
mv -f "./.my.cnf" "/root/.my.cnf" 


sleep 2

printf "$KEYSTONE_DBPASS"

printf "Running OpenStack Playbook"
ansible-playbook ./openstack.yml

