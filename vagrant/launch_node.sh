LIBVIRT_IMAGE_DIR=${LIBVIRT_IMAGE_DIR:-/var/lib/libvirt/images}
DATE=`date +"%s"`
NAME="node_${DATE}"
PRIMARY_DISK_SIZE="80"
ADDITIONAL_DISKS_SIZE="30"
NETWORK="home-cluster-devel"
CPUS=4
MEMORY="4096"
echo " ===> Setting MEMORY=${MEMORY} and CPUS=${CPUS}"

echo "Verifying expected network:"
virsh net-info ${NETWORK}
if [ "$?" != 0 ]; then
  echo "Unable to find network: ${NETWORK}"
  echo "Perhaps you want to run as 'sudo'?"
  echo "Please update and continue."
  exit 1
fi
mkdir -p .libvirt/images

virt-install \
  --name ${NAME} \
  --vcpus=${CPUS} \
  --ram=${MEMORY} \
  --os-type=linux \
  --disk path=${LIBVIRT_IMAGE_DIR}/${NAME}.img,bus=virtio,sparse=true,format=raw,cache=unsafe,size=${PRIMARY_DISK_SIZE} \
  --disk path=${LIBVIRT_IMAGE_DIR}/${NAME}2.img,bus=virtio,sparse=true,format=raw,cache=unsafe,size=${ADDITIONAL_DISKS_SIZE} \
  --pxe \
  --accelerate \
  --graphics vnc \
  --noautoconsole \
  --hvm \
  --network bridge:virbr117 \
  --boot network,hd
