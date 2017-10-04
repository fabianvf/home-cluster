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

virt-install \
  --name ${NAME} \
  --vcpus=${CPUS} \
  --ram=${MEMORY} \
  --os-type=Linux \
  --os-variant=centos7 \
  --disk pool=/var/lib/libvirt/images/${NAME}.img,bus=virtio,format=qcow2,size=${DISK_SIZE} \
  --pxe \
  --accelerate
  --graphics vnc \
  --noautoconsole \
  --hvm \
  --network network=${NETWORK} \
  --boot network,hd
