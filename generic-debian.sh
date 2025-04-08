#!/bin/bash

# Build a Debian image for a virt-builder local repo with a fixed size
#
# Example usage:
#   osinfo='debian12' \
#   cloudImageURL='https://cdimage.debian.org/images/cloud/bookworm/latest/debian-12-genericcloud-amd64.qcow2' \
#   imageSize=30G \
#   bash generic-debian.sh

set -euo pipefail

diskImagePath=${diskImagePath:='imgs'}
osinfo=${osinfo:='none'}
cloudImageURL=${cloudImageURL:='none'}
imageSize=${imageSize:='none'}

imageName="${osinfo}-${imageSize}.qcow2"

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

  # Copy and resize the image
  echo "🧱 Creating image '${imageName}' with size ${imageSize}..."
  cp -a --sparse=always "$cloudImageFile" "$imagePathFull"
  qemu-img resize "$imagePathFull" "$imageSize"

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
  virt-customize -a "$imagePathFull" --copy-in rc.local:/etc/
  virt-customize -a "$imagePathFull" --run-command 'chmod +x /etc/rc.local'
  virt-customize -a "$imagePathFull" --run-command 'systemctl enable rc-local'

  # Inject SSH key and install dependencies
  echo "🔑 Injecting SSH key and preparing system..."
  virt-customize -a "$imagePathFull" --ssh-inject root:file:${diskImagePath}/virt-local-key.pub
  virt-customize -a "$imagePathFull" --selinux-relabel
  virt-customize -a "$imagePathFull" --run-command 'mkdir -p /root/.ssh && chmod 700 /root/.ssh'
  virt-customize -a "$imagePathFull" --run-command 'apt update && apt install -y python3 python3-pip cloud-guest-utils && apt clean'
  virt-customize -a "$imagePathFull" --copy-in ${diskImagePath}/virt-local-key:/root/.ssh/
  virt-customize -a "$imagePathFull" --run-command 'mv /root/.ssh/virt-local-key /root/.ssh/id_rsa && chmod 600 /root/.ssh/id_rsa'

  # Generate the virt-builder metadata
  echo "🛠  Generating virt-builder metadata..."
  osinfo="${osinfo}" imageName="${imageName%.qcow2}" diskImagePath="${diskImagePath}" imagePathFull="${imagePathFull}" bash build-metadata.sh
else
  echo "✅ Image ${imagePathFull} already exists. Skipping creation."
fi

