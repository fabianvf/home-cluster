#!/usr/bin/bash

set -e
vagrant destroy
vagrant up --provision

sed '/\[foreman\]/a foreman.example.org' ../hosts.example > ../inventory/hosts

(cd .. ; ansible-playbook -i inventory playbooks/foreman.yml -e "authorized_keys=$(cat ~/.ssh/id_rsa.pub)" -e "tftp_servername=192.168.17.11" -e "dns_interface=eth1")
