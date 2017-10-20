#!/usr/bin/bash
textred=$(tput setaf 1)
cat << EOF
  ${textred}WARNING: This script is going to make modifications as root to your libvirt networks
           and NetworkManager configuration. If you don't want this to happen, or you 
           want to review those changes thoroughly before running the script, hit ctrl+c
           now and read it.

           Continuing in 10 seconds

EOF
read -t 10
tput sgr0

# BEGIN: Dependencies

python -c 'import netaddr'
if [[ "$?" -ne 0 ]]; then
  echo "${textred}You must install the python netaddr module"
  tput sgr0
  exit 1
fi


for plugin in "vagrant-libvirt" "vagrant-hostmanager" ; do
  if [[ -z "$(vagrant plugin list | grep ${plugin})" ]]; then
    echo "${textred}You must install the ${plugin} vagrant plugin"
    tput sgr0
    exit 1
  fi
done

# END: Dependencies

# BEGIN: Network configuration
if [[ -z "$(grep 'dns=dnsmasq' /etc/NetworkManager/NetworkManager.conf)" ]] ; then
cat << EOF
  ${textred}WARNING: It looks like NetworkManager is not configured to use dnsmasq. I'm about to modify
           the dns setting in the [main] section of your /etc/NetworkManager/NetworkManager.conf

           If you don't want me mucking with your networking settings, hit ctrl+c now!

           Continuing in 30 seconds. This is your last chance!

EOF
  tput sgr0
  read -t 30
  set -x
  sudo sed -i 's/dns=.*/dns=dnsmasq/' /etc/NetworkManager/NetworkManager.conf
fi

set -x
cat << EOF | sudo tee /etc/NetworkManager/dnsmasq.d/home-cluster.conf
address=/foreman.example.org/192.168.17.11
server=/example.org/192.168.17.11
server=/17.168.192.in-addr.arpa/192.168.17.11
EOF
sudo systemctl restart NetworkManager

# END: Network configuration

# BEGIN: VM configuration
mkdir -p .vagrant/content/{atomic,fedora-atomic}

sudo virsh net-destroy home-cluster-devel
sudo virsh net-undefine home-cluster-devel
sudo virsh net-define network.xml
sudo virsh net-start home-cluster-devel

set -e
vagrant destroy
vagrant up --provision

# END: VM configuration

(cd .. ; ansible-playbook -i inventory playbooks/foreman.yml -e "foreman_dns_interface=eth1" -e "foreman_subdomain=example.org" -e "foreman_hostname=foreman")

if [[ ! -z "$(vagrant plugin list | grep rsync-back)" ]]; then
  vagrant rsync-back
fi
