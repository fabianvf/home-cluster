DATE=`date +"%s"`
NAME="node_${DATE}"
DISK_SIZE="80"
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
  --disk path=/home/libvirt/images/${NAME}.img,bus=virtio,sparse=true,format=raw,cache=unsafe,size=${DISK_SIZE} \
  --pxe \
  --accelerate \
  --graphics vnc \
  --noautoconsole \
  --hvm \
  --network bridge:virbr2 \
  --boot network,hd
  # --os-variant=centos \ --network network=${NETWORK}\
