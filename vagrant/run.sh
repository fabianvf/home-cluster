#!/usr/bin/bash

python -c 'import netaddr'
if [[ "$?" -ne 0 ]]; then
 echo "You must install the python netaddr module"
 exit 1
fi

sudo virsh net-destroy home-cluster-devel
sudo virsh net-undefine home-cluster-devel
sudo virsh net-define network.xml
sudo virsh net-start home-cluster-devel

set -e
vagrant destroy
vagrant up --provision

sed '/\[foreman\]/a foreman.example.org' ../hosts.example > ../inventory/hosts

(cd .. ; ansible-playbook -i inventory playbooks/foreman.yml -e "foreman_dns_interface=eth1")
