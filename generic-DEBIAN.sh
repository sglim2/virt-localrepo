#!/bin/bash

# Build a local base image for Debian
#
# example:
#
#   imageName='debian-bookworm-baseimage.qcow2' \
#   cloudImageURL='https://cdimage.debian.org/images/cloud/bookworm/latest/debian-12-genericcloud-amd64.qcow2' \
#   bash generic-DEBIAN.sh 

diskImagePath=${diskImagePath:='imgs'}
imageName=${imageName:='none'}
cloudImageURL=${cloudImageURL:='none'}

if [[ ${cloudImageURL} == 'none' ]] ; then
  echo "Please specify 'cloudImageURL'"
  exit 1
fi

if [[ ${imageName} == 'none' ]] ; then
  echo "Please specify 'imageName'"
  exit 1
fi

echo "Checking for ssh keys"
[ -f ${diskImagePath}/virt-local-key ] || ssh-keygen -C "virt-local" -t rsa -b 2048 -N "" -f ${diskImagePath}/virt-local-key

echo "Checking/Downloading official image"
if [[ ! -f ${diskImagePath}/${imageName} ]] ; then
  [ -f "${diskImagePath}/${cloudImageURL##*/}" ] || curl -L ${cloudImageURL} -o ${diskImagePath}/${cloudImageURL##*/}
  cp -a --sparse=always ${diskImagePath}/"${cloudImageURL##*/}" ${diskImagePath}/${imageName}

  # Create a first-boot script to resize the last partition and filesystem
  cat << 'EOF' > rc.local
#!/bin/bash
# Get the last partition of /dev/vda
last_partition=$(lsblk -nrpo NAME /dev/vda | tail -n1)
# Grow the last partition
growpart /dev/vda ${last_partition##*vda}
# Resize the filesystem on the last partition
resize2fs ${last_partition}
# Disable this script
systemctl disable rc-local
# Remove this script
rm -f /etc/rc.local
EOF


  # Copy the first-boot script into the image and make it executable
  virt-customize -a ${diskImagePath}/${imageName} --copy-in rc.local:/etc/
  virt-customize -a ${diskImagePath}/${imageName} --run-command 'chmod +x /etc/rc.local'
  virt-customize -a ${diskImagePath}/${imageName} --run-command 'systemctl enable rc-local'

  # copy and inject key
  echo "Injecting ssh keys, and selinux relabelling"
  virt-customize -a ${diskImagePath}/${imageName} --ssh-inject root:file:${diskImagePath}/virt-local-key.pub
  virt-customize -a ${diskImagePath}/${imageName} --selinux-relabel
  virt-customize -a ${diskImagePath}/${imageName} --run-command 'mkdir -p /root/.ssh && chmod 700 /root/.ssh'
  virt-customize -a ${diskImagePath}/${imageName} --run-command 'apt update && apt install -y python3 python3-pip cloud-guest-utils && apt clean'
  virt-customize -a ${diskImagePath}/${imageName} --copy-in ${diskImagePath}/virt-local-key:/root/.ssh/
  virt-customize -a ${diskImagePath}/${imageName} --run-command 'mv /root/.ssh/virt-local-key /root/.ssh/id_rsa && chmod 600 /root/.ssh/id_rsa'

  # build metadata file
  imageName=${imageName} diskImagePath=${diskImagePath} bash build-metadata.sh 
fi
