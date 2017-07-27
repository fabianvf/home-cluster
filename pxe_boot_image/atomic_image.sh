# TODO make this a real script

echo "THIS IS NOT A REAL SCRIPT DO NOT RUN IT"
exit(1)

# TODO Download livecd image if no pxe bootable image already exists
# Install livecd-tools
sudo dnf install livecd-tools
mkdir pxe
cd pxe
mv ~/Downloads/CentOS-Atomic-Host-7-Installer.iso pxe/atomic.iso
# Run livecd-iso-to-pxeboot on livecd to generate pxeboot crap
sudo livecd-iso-to-pxeboot atomic.iso # --ks anaconda-ks.cfg
# Edit your pxelinux.cfg to present the options you want
vim tftpboot/pxelinux.cfg/default
# adding a ks=url allows me to customize my kickstart easily without rebaking the bootable image
# Need to make sure you get the LABEL correct or shit will break

# Content of my tftpboot/pxelinux.cfg/default
"DEFAULT pxeboot
TIMEOUT 60
PROMPT 20

MENU TITLE Fabian's house PXE Menu

LABEL pxeboot
MENU LABEL Atomic Host (CentOS 7)
KERNEL vmlinuz
APPEND rootflags=loop ks=http://fabianism.local/kickstarts/centos-atomic.cfg root=live:/atomic.iso debug rootfstype=auto initrd=initrd.img inst.stage2=hd:LABEL=CentOS\x20Atomic\x20Host\x207\x20x86_64 quiet
ONERROR LOCALBOOT 0"

# then just need to stick it into a place that allows you to serve it with tftp
# with freenas just need to enable the tftp service and configure the service to point to your pxe_boot directory
# dhcp-boot=pxelinux.0,freenas.local,192.168.1.252
