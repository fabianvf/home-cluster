My home private cloud

# Goals
This is a repository of playbooks/scripts to deploy, configure, and manage a private cloud for your home (well, my home). Ideally I'd like this to be an easy way to set up your own home private cloud and scale it easily on hardware you have laying around. This would be useful for things like setting up your home with local network backups or connecting IOT devices (like security cameras and other sensors) without needing to send all your information to some third party.

# Motivation
My wife is a photographer, and generates between 1TB and 3TB of media per year. I am a software engineer working on Openshift, and have a variety of applications running on our local network, spread around a ton of hardware. I'm sick of manually configuring/fixing things, and was hoping to leverage some of my professional experience to provide a secure local network backup system for my wife, and a good platform for hosting/running applications for me.

# Roadmap
- [x] Foreman deploy (including TFTP and DNS)
- [x] Sync Fedora Atomic images to Foreman
- [x] Provision nodes with Fedora Atomic
- [x] Deployment of Openshift Origin
- [ ] Deployment of Heketi and gluster
  - [ ] Configuration of gluster for dynamic persistent volume provisioning
- [ ] Deployment and configuration of various services (feel free to add PRs to expand this list, it's a wishlist)
  - [ ] [Seafile](https://www.seafile.com/en/home/) 
    - [Containerized: yes](https://github.com/haiwen/seafile-docker) (just not built yet) (official)
    - GPL v2.0
  - [ ] [Collabora online](https://www.collaboraoffice.com/)
    - [Containerized: yes](https://hub.docker.com/r/collabora/code/) (official)
    - License unknown, but they claim it is FOSS. LibreOffice is Mozilla Public License v2.0
  - [ ] [NextCloud](https://nextcloud.com/)
    - [Containerized: yes](https://hub.docker.com/_/nextcloud/) (official)
    - GNU AGPL v3.0
  - [ ] [ZoneMinder](https://zoneminder.com/)
    - [Containerized: yes](https://hub.docker.com/r/kylejohnson/zoneminder/) (unofficial, but based on official dockerfile)
    - GPL v2.0
  - [ ] [Monica](https://monicahq.com/)
    - [Containerized: yes](https://hub.docker.com/r/monicahq/monicahq/) (official)
    - GNU AGPL v3.0
  - ~~[ ] [Ambar](https://ambar.cloud/)~~
    - ~~[ ]Containerized?~~
    - Fair source licensed, disqualified
  - [ ] [Emby](https://emby.media/)
    - [Containerized: yes](https://hub.docker.com/r/emby/embyserver/) (official)
    - GPL v2.0
  - [ ] [Plex](https://www.plex.tv/)
    - [Containerized: yes](https://hub.docker.com/r/plexinc/pms-docker/) (official)
    - GPL v2.0 (for the host software, client is proprietary)
  - [ ] [Home Assistant](https://home-assistant.io/)
    - [Containerized: yes](https://hub.docker.com/r/homeassistant/home-assistant/)
    - Apache v2.0 
  - [ ] [Organizr](https://github.com/causefx/Organizr)
    - [Containerized: yes](https://hub.docker.com/r/lsiocommunity/organizr/) (community contributed, but officially endorsed)
    - GPL v3.0


# Quickstart

## Dependencies
You  will need:
- ansible >= 2.3
- python-netaddr
- python-requests
- openshift-ansible
    - pyOpenSSL
    - python-cryptography
    - python-lxml
- TODO: audit additional/implicit dependencies

For Fedora:

```bash
dnf install -y python-netaddr python-requests ansible pyOpenSSL python-cryptography python-lxml
git clone https://github.com/openshift/openshift-ansible /usr/share/ansible/openshift-ansible
```

## Virtual environment
To test out this environment, I recommend using the vagrant environment defined in the `vagrant` directory.

_Note: I'm running Fedora 26 and have not tested anything out on any other OS. Also,
this environment only supports libvirt. I would love to support virtualbox as well,
so if you know anything about virtualbox, making this work with both would be awesome._

You will need the additional dependencies of libvirt,
and the vagrant-libvirt, vagrant-hostmanager, and vagrant-rsync-back vagrant plugins.

```bash
<package manager> install -y libvirt
vagrant plugin install vagrant-libvirt
vagrant plugin install vagrant-hostmanager
vagrant plugin install vagrant-rsync
```

### Foreman

Once you have the dependencies, then for an easy setup you can just run (from inside the vagrant directory):

```bash
./run.sh
```

You may need authenticate as root a few times for the libvirt networking config to take effect. This script will set up your libvirt network for network booting, bring up the vagrant machine, and set up foreman.

If you hate the idea of running a script written by a random person that messes with your networking and libvirt environment, or if the script just doesn't work for you, then just open it up and run through the steps by hand, adjusting as needed for your environment. Feel free to open up an issue or pop into the IRC channel if you have any trouble.


### Nodes
After you've set up the foreman box, just run:

```bash
sudo ./launch_node.sh
```

to bring up a new node that will register to foreman and automatically be provisioned with Fedora Atomic. You can run this script as many times as you want until you have the desired number of openshift nodes.

## Bare Metal

For deployment onto physical hosts or external VMs (ie anything that isn't the aforementioned vagrant environment)

### Hardware
- 1 server that will host Foreman.
    - The Foreman ansible roles assume that CentOS 7 is installed on this machine, use anything else at your own risk
- N servers that will serve as openshift nodes.
    - These servers will need to be configured to network boot. Most vendors provide these settings in the BIOS screen.
    - At least one of your nodes will need to have > 1 disks, so that it can be tagged and used as a gluster storage host.

### Networking
- Foreman needs a static IP + hostname
- Your router needs to use Foreman for DNS (at least for a subdomain on your network)
- Your router needs to use Foreman for TFTP

Here's a sample dnsmasq configuration, from the vagrant environment:

```
address=/foreman.example.org/192.168.17.11
server=/example.org/192.168.17.11
server=/17.168.192.in-addr.arpa/192.168.17.11
dhcp-boot=pxelinux.0,foreman.example.org,192.168.17.11
```

### Foreman

First, copy the `config.yml.example` file to `config.yml` and open it for editing. For a basic
Foreman install, the most important options to consider are `foreman_hostname` and
`foreman_subdomain`, which you should make match the networking entries you made above. For
example, if my foreman IP is bound to `foreman.example.org`, I would set `foreman_hostname`
to `foreman`, and `foreman_subdomain` to `example.org`. It is also recommended that you change
the passwords from `changeme` to something more secure. If your Foreman machine has multiple
NICs, you may also need to manually set the `foreman_dns_interface` to the correct one, as by
default we select the primary interface from the ansible facts.

To install Foreman, just run

```bash
ansible-playbook playbooks/foreman.yml -e @config.yml
```

This should run pretty painlessly, if there are any issues during the deployment of Foreman feel free to open an issue.


## Openshift

To install openshift you will need to clone the `openshift-ansible` project. By default, we will look for `openshift-ansible`
in `/usr/share/ansible/`. To get the project there you can just run

```bash
git clone https://github.com/openshift/openshift-ansible.git /usr/share/ansible/openshift-ansible
```

If you've cloned or copied the project to another directory, you can set the location in the `openshift_ansible_dir`
in your `config.yml`

The openshift installation is the same no matter your environment. It uses a dynamic inventory pulled from Foreman, so
all you need to do is run:

```bash
ansible-playbook playbooks/nodes.yml -e @config.yml
```

This should give you a working Openshift installation, feel free to open an issue if something falls over.


# Contributions welcome!

Feel free to hop into the IRC chat, submit issues/PRs, whatever! At first this will likely be very specific to my hardware setup, but I'll work on making it more generic, which should happen naturally over time as I mix and match my hardware more.

IRC discussion on [freenode #home-cluster](https://kiwiirc.com/client/irc.freenode.net/#home-cluster)
