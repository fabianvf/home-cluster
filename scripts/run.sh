#!/bin/bash
_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
project_root=${_dir}/..

ansible-playbook playbooks/site.yml -e @${project_root}/config.yml
