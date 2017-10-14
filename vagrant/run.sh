#!/usr/bin/bash

python -c 'import netaddr'
if [[ "$?" -ne 0 ]]; then
 echo "You must install the python netaddr module"
 exit 1
fi

set -e
vagrant destroy
vagrant up --provision

sed '/\[foreman\]/a foreman.example.org' ../hosts.example > ../inventory/hosts

(cd .. ; ansible-playbook -i inventory playbooks/foreman.yml -e "foreman_dns_interface=eth1")
