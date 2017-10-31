#!/bin/bash

sync_dir=$1
mirror=${2:-dl.fedoraproject.org/fedora-alt}

if [[ "$sync_dir" == "" ]]; then
  echo "ERROR: Must provide sync_dir as first argument"
  exit 1
fi

# Just gets latest
fedora_full_version_string=$(curl https://download.fedoraproject.org/pub/alt/atomic/stable -L | grep "Fedora-Atomic" | tail -n1 |  sed -rn 's|.*<a href="(.*)/">.*|\1|p')
fedora_version=$(echo $fedora_full_version_string | awk -F "-" '{print $3}')

echo "============================================================"
echo "Syncing content:"
echo "sync_dir: [ $sync_dir ]"
echo "mirror: [ $mirror ]"
echo "fedora_version: [ $fedora_version ]"
echo "fedora_full_version_string: [ $fedora_full_version_string ]"
echo "============================================================"

mkdir -p ${sync_dir}

/usr/bin/rsync \
  --delay-updates -F \
  --compress \
  --archive \
  --include "/atomic" \
  --include "/atomic/stable" \
  --include "/atomic/stable/$fedora_full_version_string" \
  --include "/atomic/stable/$fedora_full_version_string/Atomic" \
  --include "/atomic/stable/$fedora_full_version_string/Atomic/x86_64" \
  --include "/atomic/stable/$fedora_full_version_string/Atomic/x86_64/os" \
  --include "/atomic/stable/$fedora_full_version_string/Atomic/x86_64/os/**" \
  --exclude "*" \
  --out-format='<<CHANGED>>%i %n%L' \
  rsync://dl.fedoraproject.org/fedora-alt ${sync_dir}/fedora-atomic
