#!/bin/bash
ANSIBLE_HOSTS=""
HOSTS_FILE=""
# ANSIBLE_ECHO="$(ansible openstack -a "printf "SUCCESS"")" 
# change this
USER="/root"

printf "Verfying requirements..."

if [[ ! -e $USER/.ssh ]]
then
  printf "$(mkdir $USER/.ssh)"
elif [[ ! -e $USER/.ssh/authorized_keys ]]
then
  printf "$(touch $USER/.ssh/authorized_keys)"
  printf "$(chown $USER:$USER $USER/.ssh/authorized_keys)"
  printf "$(chmod 700 %USER/.ssh/authorized_keys)"
fi

# haven't tested on versions less than 6.0
if [[ $(cat /etc/issue) == *"CentOS"*||*"RedHat" ]]
then
  printf "Distribution: RHEL\n"
  if [[ $(grep -o "[0-9].[0-9]" /etc/issue) > "5.9" ]]
    then
    printf "Version: 6.5\n"
    printf "Good to go\n"
  else
    printf "Requires 6.0 or above\n"
  exit
  fi
else
  printf "RHEL required\n"
fi

# check for and install initial packages
if [[ $(rpm -q ansible) == *"not installed"* ]]
then
  printf "Requires ansible to run, installing... \n\n"
  "$(yum install ansible -y)"
fi

# allow local ssh access
printf "Generating ssh key\n\n"
printf "$(ssh-keygen -t rsa -N "" -f $USER/.ssh/id_rsa)"
printf "$(ssh-keyscan controller > $USER/.ssh/known_hosts)"
printf "$(cat $USER/.ssh/id_rsa.pub >> $USER/.ssh/authorized_keys)"

# expect is very picky, so letting the playbook do a fresh install is recommended
if [[ -d "/var/lib/mysql" ]]
then
  printf "WARNING: /var/lib/mysql data dir already set up. Remove data directory and existing install or may cause issues with automatic mysql_secure_installation script\n"
  while true; do
    read -p "Complete quality check process? [y/n]: " yn
    case $yn in
      [Yy]* ) break;;
      [Nn]* ) printf "FAILED: /var/lib/mysql data dir present" > "./status.tmp" && exit;;
       * ) printf "Please enter yes or no.\n";;
     esac
  done
  else 
    printf "MySQL Data Dir is clean\n"
fi

printf "Checking for ansible hostfile...\n\n"

ANSIBLE_HOSTS="$(grep hostfile /etc/ansible/ansible.cfg|awk '{print $3}')"

printf $ANSIBLE_HOSTS

printf "Checking for "openstack" group in ansible config..."

if [[ "$(grep openstack $ANSIBLE_HOSTS)" == "" ]]
then
  printf "Adding hosts...\n"
  printf "[openstack]" >> "$ANSIBLE_HOSTS"
  printf "\n$(grep openstack= ./nodes.cfg|cut -d '=' -f2|tr ',' '\n'|tr -d ' ')" >> "$ANSIBLE_HOSTS"
  printf "\n[controller]" >> "$ANSIBLE_HOSTS"
  printf "\n$(grep controller= ./nodes.cfg|cut -d '=' -f2|tr ',' '\n'|tr -d ' ')" >> "$ANSIBLE_HOSTS"
fi

printf "$ANSIBLE_ECHO"


# run check
$(ansible openstack -a "printf \"Hello, world\"" > ./tmp.txt)

if [[ $(grep "FAILED" ./tmp.txt) ]]
then
  printf "Something went wrong, quitting..."
else
  printf "STAGE 2" > "./status.tmp"
  exit
fi


exit
