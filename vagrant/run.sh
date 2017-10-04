#!/usr/bin/bash

vagrant up --no-provision
vagrant provision

sed '/\[foreman\]/a foreman.example.org' ../hosts.example > ../inventory/hosts

(cd .. ; ansible-playbook -i inventory playbooks/foreman.yml -e "authorized_keys=$(cat ~/.ssh/id_rsa.pub)")
