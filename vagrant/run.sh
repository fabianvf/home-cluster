#!/usr/bin/bash

set -e
vagrant destroy
vagrant up --provision

sed '/\[foreman\]/a foreman.example.org' ../hosts.example > ../inventory/hosts

(cd .. ; ansible-playbook -i inventory playbooks/foreman.yml -e "foreman_dns_interface=eth1")
