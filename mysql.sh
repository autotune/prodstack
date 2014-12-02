#!/bin/bash
source ./openstack.rc


if [[ $(rpm -q mysql-server) == *"not installed"* ]]
then
  echo "mysql-server not installed, aborting..."
  exit
fi

if [[ $(/etc/init.d/mysqld) != *running* ]]
then
  echo "Starting mysql-server..."
  echo "$(/etc/init.d/mysqld start)"
else
  exit
fi

echo "Running mysql_secure_installation..."

sleep 2

echo "Generating random password for mysql root user..."

sleep 2

KEYSTONE_DBPASS="$(openssl rand -base64 8)"

# echo "$KEYSTONE_DBPASS"

# export reads environment vars so need to export

# echo "$(export $KEYSTONE_DBPASS)" 
SECURE_MYSQL=$(expect -c "
 
spawn mysql_secure_installation
 
expect \"Enter current password for root (enter for none):\"
send \"\r\"
 
expect \"Set root password?\"
send \"y\r\"

expect \"New password: \"
send \"34efwasfasd\r\"

expect \"Re-enter new password: \"
send \"34efwasfasd\r\"
 
expect \"Remove anonymous users?\"
send \"y\r\"
 
expect \"Disallow root login remotely?\"
send \"y\r\"
 
expect \"Remove test database and access to it?\"
send \"y\r\"
 
expect \"Reload privilege tables now?\"
send \"y\r\"
 
expect eof
")
 
echo "$SECURE_MYSQL"

echo "Replacing password in /tmp/prodstack/.my.cnf file..."
echo "$KEYSTONE_DBPASS"
# echo "$(sed -i "s/pass=/pass=$KEYSTONE_DBPASS/g" "/tmp/prodstack/.my.cnf")"
# echo "Copying to ~/.my.cnf..."
# echo "$(mv -f /tmp/prodstack/.my.cnf ~/.my.cnf)"
exit 1
