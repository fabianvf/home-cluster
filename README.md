My home private cloud

# Goals
This is a repository of playbooks/scripts to deploy, configure, and manage a private cloud for your home (well, my home). Ideally I'd like this to be an easy way to set up your own home private cloud and scale it easily on hardware you have laying around. This would be useful for things like setting up your home with local network backups or connecting IOT devices (like security cameras and other sensors) without needing to send all your information to some third party.

# Motivation
My wife is a photographer, and generates between 1TB and 3TB of media per year. I am a software engineer working on Openshift, and have a variety of applications running on our local network, spread around a ton of hardware. I'm sick of manually configuring/fixing things, and was hoping to leverage some of my professional experience to provide a secure local network backup system for my wife, and a good platform for hosting/running applications for me.

# Roadmap
- [x] Deployment of Openshift Origin single node install
- [ ] Deployment of TFTP to install fedora atomic on nodes
- [ ] Deployment of AWX for node scaleup
    - [x] Awx deployment
    - [x] awx resource creation to enable node scaleup (incl openshift-ansible project import)
    - [ ] Job trigger for node discovery
    - [ ] Dynamic inventory to allow scaleup on registration of new nodes
- [x] Deployment of Rook and Ceph
  - [x] Configuration of rook/ceph for dynamic persistent volume provisioning
- [ ] Deployment and configuration of various services (will be worked on in the order listed, feel free to add PRs to expand this list)
  - [ ] [ZoneMinder](https://zoneminder.com/)
    - [Containerized: yes](https://hub.docker.com/r/kylejohnson/zoneminder/) (unofficial, but based on official dockerfile)
    - GPL v2.0
  - [ ] [Home Assistant](https://home-assistant.io/)
    - [Containerized: yes](https://hub.docker.com/r/homeassistant/home-assistant/)
    - Apache v2.0
  - [ ] [Seafile](https://www.seafile.com/en/home/)
    - [Containerized: yes](https://github.com/haiwen/seafile-docker) (just not built yet) (official)
    - GPL v2.0
  - [ ] [NextCloud](https://nextcloud.com/)
    - [Containerized: yes](https://hub.docker.com/_/nextcloud/) (official)
    - GNU AGPL v3.0
  - [ ] [Collabora online](https://www.collaboraoffice.com/)
    - [Containerized: yes](https://hub.docker.com/r/collabora/code/) (official)
    - License unknown, but they claim it is FOSS. LibreOffice is Mozilla Public License v2.0
  - [ ] Streama (https://streamaserver.org)
      - [Containerized: yes](https://hub.docker.com/r/gkiko/streama) (official I think?)
      - MIT
  - [ ] [Organizr](https://github.com/causefx/Organizr)
    - [Containerized: yes](https://hub.docker.com/r/lsiocommunity/organizr/) (community contributed, but officially endorsed)
    - GPL v3.0
  - [ ] [Monica](https://monicahq.com/)
    - [Containerized: yes](https://hub.docker.com/r/monicahq/monicahq/) (official)
    - GNU AGPL v3.0
  - [ ] [Emby](https://emby.media/)
    - [Containerized: yes](https://hub.docker.com/r/emby/embyserver/) (official)
    - GPL v2.0
  - [ ] [Plex](https://www.plex.tv/)
    - [Containerized: yes](https://hub.docker.com/r/plexinc/pms-docker/) (official)
    - GPL v2.0 (for the host software, client is proprietary)


# Quickstart

## Dependencies
You  will need:
- docker
- ansible >= 2.5

For Fedora:

```bash
dnf install -y python-netaddr python-requests ansible pyOpenSSL python-cryptography python-lxml
```

## Virtual environment
To test out this environment, I recommend using the vagrant environment defined in the top-level `Vagrantfile`.

_Note: I'm running Fedora 26 and have not tested anything out on any other OS. Also,
this environment only supports libvirt. I would love to support virtualbox as well,
so if you know anything about virtualbox, making this work with both would be awesome._

You will need the additional dependencies of libvirt,
and the vagrant-libvirt, vagrant-hostmanager, and vagrant-triggers vagrant plugins.

```bash
<package manager> install -y libvirt
vagrant plugin install vagrant-libvirt
vagrant plugin install vagrant-hostmanager
vagrant plugin install vagrant-triggers
```

Once you have the dependencies, then for an easy setup you can just run (from the top-level):

```bash
vagrant up
```

There are a few environment variables that can be set to alter the behavior of the virtual environment:

| name | description |
|------|-------------|
|NUM_NODES | number of openshift nodes to bring up|
|ONLY_NODES | makes the commands only affect the node vms, ie `ONLY_NODES vagrant destroy` would tear down all the nodes but leave your foreman instance up|
|VERBOSITY | verbosity level to run Ansible (ie, `v`, `vv`, `vvv`)|


## Real deployment

For deployment onto physical hosts or external VMs (ie anything that isn't the aforementioned vagrant environment)

### Hardware
- 1 server that will host the first master
    - Needs to be running fedora atomic
    - Needs at least 2 disks
- N servers that will serve as openshift nodes.
    - These servers will need to be configured to network boot.
    - Any disks other than the boot disk will be used for storage

### Networking
- The first master will need to have a static IP and hostname
- Your router will need to be configured to use the first master for DNS (for your local subdomain) and TFTP
- Your router will need to be configured to use the first master for TFTP

Here's a sample dnsmasq configuration, from the vagrant environment:

```
address=/master.example.org/192.168.17.11
server=/example.org/192.168.17.11
server=/17.168.192.in-addr.arpa/192.168.17.11
dhcp-boot=pxelinux.0,master.example.org,192.168.17.11
```

### Configuration

There's a file named `config.yml` at the top level of the project. It contains all of the configuration required to deploy
the project. There are two sections to the config.yml, a User variable section and a Project variable section. The user
variables are meant to be modified your environment or to trigger different features. They should be well-documented inline.
The Project variables are more low-level, required for the project to run. They can still be modified, but have a high chance
of breaking.

### Deployment

If you have a server up, add it to the `first_master` section of the top-level `inventory`, then run:

```bash
ansible-playbook playbooks/deploy.yml
```

This should give you a working Openshift + Ceph + AWX installation.

Additional services can be configured in the `config.yml` to be included in the first installation, or you can go
to the newly deployed Openshift web console and deploy them from the interface there.


# Contributions welcome!

Feel free to hop into the IRC chat, submit issues/PRs, whatever! At first this will likely be very specific to my hardware setup, but I'll work on making it more generic, which should happen naturally over time as I mix and match my hardware more.

IRC discussion on [freenode #home-cluster](https://kiwiirc.com/client/irc.freenode.net/#home-cluster)
