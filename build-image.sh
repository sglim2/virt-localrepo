#!/bin/bash

# Build a Linux VM image for a virt-builder local repo
#
# Example usage:
#   osinfo='rocky9' cloudImageURL='https://download.rockylinux.org/pub/rocky/9/images/x86_64/Rocky-9-GenericCloud-Base.latest.x86_64.qcow2' bash build-image.sh

set -euo pipefail

diskImagePath=${diskImagePath:='imgs'}
osinfo=${osinfo:='none'}
cloudImageURL=${cloudImageURL:='none'}

imageName="${osinfo}.qcow2"

if [[ $cloudImageURL == 'none' ]]; then
  echo "❌ Please specify 'cloudImageURL'"
  exit 1
fi

if [[ $osinfo == 'none' ]]; then
  echo "❌ Please specify 'osinfo'"
  exit 1
fi

imagePathFull="${diskImagePath}/${imageName}"

echo "🔐 Checking for SSH keys..."
[ -f ${diskImagePath}/virt-local-key ] || ssh-keygen -C "virt-local" -t rsa -b 2048 -N "" -f ${diskImagePath}/virt-local-key

echo "🌐 Checking/Downloading official image..."
if [[ ! -f "${imagePathFull}" ]]; then
  # Download cloud image if not already downloaded
  cloudImageFile="${diskImagePath}/${cloudImageURL##*/}"
  if [[ ! -f "$cloudImageFile" ]]; then
    curl -L "$cloudImageURL" -o "$cloudImageFile"
  fi

  # Copy the image
  echo "🧱 Creating image '${imageName}'..."
  cp -a --sparse=always "$cloudImageFile" "$imagePathFull"

  # Inject SSH key
  echo "🔑 Injecting SSH key and SELinux relabel..."
  virt-customize -a "$imagePathFull" --ssh-inject root:file:${diskImagePath}/virt-local-key.pub
  virt-customize -a "$imagePathFull" --selinux-relabel
  virt-customize -a "$imagePathFull" --run-command 'mkdir -p /root/.ssh && chmod 700 /root/.ssh'
  virt-customize -a "$imagePathFull" --copy-in ${diskImagePath}/virt-local-key:/root/.ssh/
  virt-customize -a "$imagePathFull" --run-command 'mv /root/.ssh/virt-local-key /root/.ssh/id_rsa && chmod 600 /root/.ssh/id_rsa'

  # Generate the virt-builder metadata
  echo "🛠  Generating virt-builder metadata..."
  osinfo="${osinfo}" diskImagePath="${diskImagePath}" imagePathFull="${imagePathFull}" bash build-metadata.sh
else
  echo "✅ Image ${imagePathFull} already exists. Skipping creation."
fi

