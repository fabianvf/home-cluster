A home private cloud

# Goals
This is a repository of playbooks/scripts to deploy, configure, and manage a private cloud for your home. Ideally I'd like this to be an easy way to set up your own home private cloud and scale it easily on hardware you have laying around. This would be useful for things like setting up your home with local network backups or connecting IOT devices (like security cameras and other sensors) without needing to send all your information to some third party.

# Motivation
My wife is a photographer, and generates between 1TB and 3TB of media per year. I am a software engineer working on OpenShift, and have a variety of applications running on our local network, spread around a ton of hardware. I'm sick of manually configuring/fixing things, and was hoping to leverage some of my professional experience to provide a secure local network backup system for my wife, and a good platform for hosting/running applications for me.

# Functionality
- Deployment of multi-node (single master) Kubernetes cluster
- Deployment of metallb and ingress-nginx for ingress
- Deployment of rook-ceph for storage
  - Configuration of rook/ceph for dynamic persistent volume provisioning
- Automatic cluster backups
  - Deployment of minio as an NFS gateway
  - Deployment of velero with scheduled backups to the minio gateway
- Deployment and configuration of various services (see github issues for tracking of individual services)
  - Murmur (mumble server)

# Quickstart

## Dependencies
You  will need:
- Ansible >= 2.9
- the community.kubernetes Ansible collection

For Fedora:

```bash
dnf install -y ansible
ansible-galaxy collection install community.kubernetes
```

## Virtual environment
To test out this environment, I recommend using the vagrant environment defined in the top-level `Vagrantfile`.

_Note: I'm running Fedora 31 and have not tested anything out on any other OS. Also,
this environment only supports libvirt. I would love to support virtualbox as well,
so if you know anything about virtualbox, making this work with both would be awesome._

You will need the additional dependencies of libvirt,
and the vagrant-libvirt, vagrant-hostmanager, and vagrant-triggers vagrant plugins.

For Fedora

```bash
dnf install -y libvirt vagrant-libvirt vagrant-hostmanager
```

Once you have the dependencies, then for an easy setup you can just run (from the top-level):

```bash
vagrant up --no-parallel
```

There are a few environment variables that can be set to alter the behavior of the virtual environment:

| name | description |
|------|-------------|
|NUM_NODES | number of openshift nodes to bring up|
|VERBOSITY | verbosity level to run Ansible (ie, `v`, `vv`, `vvv`)|
|PLAYBOOK | path to a specific playbook to run during provisioning. Useful if you need to rerun something.|
|NODE_RAM | amount of memory to dedicate to each node (in MiB) (default 2000)|


## Real deployment

For deployment onto physical hosts or external VMs (ie anything that isn't the aforementioned vagrant environment)

### Hardware
- 1 server that will host the control-plane
    - Currently only supports centos 7 (PRs welcome)
- N servers that will serve as Kubernetes nodes.
    - Any disks other than the boot disk will be used for storage

### Networking
- All nodes will need static IPs and hostnames
- You will need to have a range of IP addresses that don't fall within your DHCP range that you can allow metallb to control.
- After deployment, the hosts defined in your ingresses won't have corresponding DNS entries. You can fix this by adding
    a wildcard DNS entry that points your cluster's subdomain at the loadbalancer IP for the ingress-nginx service. This IP
    will be printed out in the report that is generated at the end of the playbook run.

Here's a sample dnsmasq configuration, from the vagrant environment:

```
address=/.example.org/192.168.17.100
```

### Configuration

There's a file named `config.yml` at the top level of the project. It contains all of the configuration required to deploy
the project. There are two sections to the config.yml, a User variable section and a Project variable section. The user
variables are meant to be modified based on your environment or to trigger different features. They should be well-documented inline.
The Project variables are more low-level, required for the project to run. They can still be modified, but have a higher chance
of breaking something.

### Deployment

Once your servers are up and running, modify the `inventory` file to include the node that will host your control-plane
under the `first_node` group, and all nodes (including your `first_node`) under the `nodes` group.

```bash
ansible-playbook -i inventory playbooks/deploy.yml -e @config.yml
```

This should give you a working Kubernetes + Metallb + Rook/Ceph installation.

Additional services can be configured in the `config.yml` to be included in the first installation, or you can install
them later using the `playbooks/apps.yml` playbook.

# Contributions welcome!

Feel free to hop into the IRC chat, submit issues/PRs, whatever! At first this will likely be very specific to my hardware setup, but I'll work on making it more generic, which should happen naturally over time as I mix and match my hardware more.

IRC discussion on [libera.chat #home-cluster](https://kiwiirc.com/nextclient/irc.libera.chat/#home-cluster)
