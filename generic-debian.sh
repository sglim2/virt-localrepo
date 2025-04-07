#!/bin/bash

# Build a Debian image for a virt-builder local repo with a fixed size
#
# Example usage:
#   imageName='debian-bookworm-baseimage.qcow2' \
#   cloudImageURL='https://cdimage.debian.org/images/cloud/bookworm/latest/debian-12-genericcloud-amd64.qcow2' \
#   imageSize=30G \
#   bash generic-debian.sh

set -euo pipefail

diskImagePath=${diskImagePath:='imgs'}
imageName=${imageName:='none'}
cloudImageURL=${cloudImageURL:='none'}
imageSize=${imageSize:='none'}

if [[ $cloudImageURL == 'none' ]]; then
  echo "❌ Please specify 'cloudImageURL'"
  exit 1
fi

if [[ $imageName == 'none' ]]; then
  echo "❌ Please specify 'imageName'"
  exit 1
fi

if [[ $imageSize == 'none' ]]; then
  echo "❌ Please specify 'imageSize' (e.g., 30G)"
  exit 1
fi

# Strip .qcow2 from imageName and append size to name
baseName="${imageName%.qcow2}"
sizedImageName="${baseName}-${imageSize}.qcow2"
sizedImagePath="${diskImagePath}/${sizedImageName}"

echo "🔐 Checking for SSH keys..."
[ -f ${diskImagePath}/virt-local-key ] || ssh-keygen -C "virt-local" -t rsa -b 2048 -N "" -f ${diskImagePath}/virt-local-key

echo "🌐 Checking/Downloading official image..."
if [[ ! -f "${sizedImagePath}" ]]; then
  # Download cloud image if not already downloaded
  cloudImageFile="${diskImagePath}/${cloudImageURL##*/}"
  if [[ ! -f "$cloudImageFile" ]]; then
    curl -L "$cloudImageURL" -o "$cloudImageFile"
  fi

  # Copy and resize the image
  echo "🧱 Creating image '${sizedImageName}' with size ${imageSize}..."
  cp -a --sparse=always "$cloudImageFile" "$sizedImagePath"
  qemu-img resize "$sizedImagePath" "$imageSize"

  # Create rc.local script to grow last partition
  cat << 'EOF' > rc.local
#!/bin/bash
last_partition=$(lsblk -nrpo NAME /dev/vda | tail -n1)
growpart /dev/vda ${last_partition##*vda}
resize2fs ${last_partition}
systemctl disable rc-local
rm -f /etc/rc.local
EOF

  # Inject and enable the rc.local script
  echo "📦 Injecting grow script..."
  virt-customize -a "$sizedImagePath" --copy-in rc.local:/etc/
  virt-customize -a "$sizedImagePath" --run-command 'chmod +x /etc/rc.local'
  virt-customize -a "$sizedImagePath" --run-command 'systemctl enable rc-local'

  # Inject SSH key and install dependencies
  echo "🔑 Injecting SSH key and preparing system..."
  virt-customize -a "$sizedImagePath" --ssh-inject root:file:${diskImagePath}/virt-local-key.pub
  virt-customize -a "$sizedImagePath" --selinux-relabel
  virt-customize -a "$sizedImagePath" --run-command 'mkdir -p /root/.ssh && chmod 700 /root/.ssh'
  virt-customize -a "$sizedImagePath" --run-command 'apt update && apt install -y python3 python3-pip cloud-guest-utils && apt clean'
  virt-customize -a "$sizedImagePath" --copy-in ${diskImagePath}/virt-local-key:/root/.ssh/
  virt-customize -a "$sizedImagePath" --run-command 'mv /root/.ssh/virt-local-key /root/.ssh/id_rsa && chmod 600 /root/.ssh/id_rsa'

  # Generate the virt-builder metadata
  echo "🛠  Generating virt-builder metadata..."
  imageName="${sizedImageName}" diskImagePath="${diskImagePath}" bash build-metadata.sh
else
  echo "✅ Image ${sizedImagePath} already exists. Skipping creation."
fi

