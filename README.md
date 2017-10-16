My home private cloud

## Goals
This is a repository of playbooks/scripts to deploy, configure, and manage a private cloud for your home (well, my home). Ideally I'd like this to be an easy way to set up your own home private cloud and scale it easily on hardware you have laying around. This would be useful for things like setting up your home with local network backups or connecting IOT devices (like security cameras and other sensors) without needing to send all your information to some third party.

## Motivation
My wife is a photographer, and generates between 1TB and 3TB of media per year. I am a software engineer working on Openshift, and have a variety of applications running on our local network, spread around a ton of hardware. I'm sick of manually configuring/fixing things, and was hoping to leverage some of my professional experience to provide a secure local network backup system for my wife, and a good platform for hosting/running applications for me.

## What will this do?
- [x] Foreman deploy (including TFTP and DNS)
- [x] Sync Fedora Atomic images to Foreman
- [x] Provision nodes with Fedora Atomic
- [x] Deployment of Openshift Origin
- [ ] Deployment of Heketi and gluster
  - [ ] Configuration of gluster for dynamic persistent volume provisioning 
- [ ] Deployment and configuration of various services (feel free to add PRs to expand this list, it's a wishlist)
  - [ ] [Seafile](https://www.seafile.com/en/home/)
  - [ ] [Collabora online](https://www.collaboraoffice.com/)
  - [ ] [NextCloud](https://nextcloud.com/) (probably mutually exclusive with seafile + collabora)
  - [ ] [ZoneMinder](https://zoneminder.com/)
  - [ ] [Monica](https://monicahq.com/)
  - [ ] [Ambar](https://ambar.cloud/)
  - [ ] [Emby](https://emby.media/)
  - [ ] [Plex](https://www.plex.tv/)
  - [ ] [Home Assistant](https://home-assistant.io/)
  
  
## Testing it out
To test out this environment, I recommend using the vagrant environment defined in the `vagrant` directory.

You  will need libvirt, ansible, the python netaddr and requests modules, and the vagrant-libvirt, vagrant-hostmanager, and vagrant-rsync-back vagrant plugins. Once you have these dependencies, just run

```bash
cd vagrant
./run.sh
```

You may need authenticate as root a few times for the libvirt networking config to take effect. This script will set up your libvirt network for network booting, bring up the vagrant machine, and set up foreman. After you run this script, run

```bash
# This will likely need to be run as root
./launch_node.sh
```

to bring up a new node that will register to foreman and automatically be provisioned with Fedora Atomic. You can run this script as many times as you want until you have the desired number of openshift nodes.


## Prerequisites

For non-vagrant deployments, here are the requirements:

### Hardware
- 1 server that will handle meta-cluster stuff (AKA, foreman + VPN). I'm currently looking at running this on an Intel NUC or something. Raspberry Pi might work, but I think there may be some issues with foreman + PXE + ARM
- N servers that will serve as openshift nodes. I'm currently using 5 old office desktops that I got on ebay for $30 each, they have Core 2 Duos and 4GB DDR3 RAM.
  - More drives is better
  - More RAM is better
  
### Networking
- Foreman needs a static IP + hostname
- Your router needs to use Foreman for DNS (at least for a subdomain on your network)
- Your router needs to use Foreman for TFTP

### Software
- ansible >= 2.3
- python-netaddr
- python-requests
- TODO: audit dependencies


## Contributions welcome!

Feel free to hop into the IRC chat, submit issues/PRs, whatever! At first this will likely be very specific to my hardware setup, but I'll work on making it more generic, which should happen naturally over time as I mix and match my hardware more. 
  
IRC discussion on [freenode #home-cluster](https://kiwiirc.com/client/irc.freenode.net/#home-cluster)
