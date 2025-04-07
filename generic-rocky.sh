#!/bin/bash

# Build a Rocky Linux image for a virt-builder local repo with a fixed size
#
# Example usage:
#   imageName='rocky9-virt-localrepo-base.qcow2' \
#   cloudImageURL='https://download.rockylinux.org/pub/rocky/9/images/x86_64/Rocky-9-GenericCloud-Base.latest.x86_64.qcow2' \
#   imageSize=30G \
#   bash generic-rocky.sh

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
xfs_growfs ${last_partition}
systemctl disable rc-local
rm -f /etc/rc.d/rc.local
EOF

  # Inject and enable the rc.local script
  echo "📦 Injecting grow script..."
  virt-customize -a "$sizedImagePath" --copy-in rc.local:/etc/rc.d/
  virt-customize -a "$sizedImagePath" --run-command 'chmod +x /etc/rc.d/rc.local'
  virt-customize -a "$sizedImagePath" --run-command 'systemctl enable rc-local'

  # Inject SSH key
  echo "🔑 Injecting SSH key and SELinux relabel..."
  virt-customize -a "$sizedImagePath" --ssh-inject root:file:${diskImagePath}/virt-local-key.pub
  virt-customize -a "$sizedImagePath" --selinux-relabel
  virt-customize -a "$sizedImagePath" --run-command 'mkdir -p /root/.ssh && chmod 700 /root/.ssh'
  virt-customize -a "$sizedImagePath" --run-command 'dnf install -y python python-devel python-pip; update-alternatives --set python /usr/bin/python3;  update-alternatives --set python3 /usr/bin/python3; dnf clean all'
  virt-customize -a "$sizedImagePath" --copy-in ${diskImagePath}/virt-local-key:/root/.ssh/
  virt-customize -a "$sizedImagePath" --run-command 'mv /root/.ssh/virt-local-key /root/.ssh/id_rsa && chmod 600 /root/.ssh/id_rsa'

  # Generate the virt-builder metadata
  echo "🛠  Generating virt-builder metadata..."
  imageName="${sizedImageName}" diskImagePath="${diskImagePath}" bash build-metadata.sh
else
  echo "✅ Image ${sizedImagePath} already exists. Skipping creation."
fi

