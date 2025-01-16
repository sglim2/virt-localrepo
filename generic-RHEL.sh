#!/bin/bash

# Build a local base image
#
# example:
#
#   imageName='rocky9-baseimage.qcow2' \
#   cloudImageURL='https://download.rockylinux.org/pub/rocky/9/images/x86_64/Rocky-9-GenericCloud-Base.latest.x86_64.qcow2'
#   bash generic-RHEL.sh 


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
xfs_growfs ${last_partition}
# Disable this script
systemctl disable rc-local
# Remove this script
rm -f /etc/rc.d/rc.local
EOF


  # Copy the first-boot script into the image and make it executable
  virt-customize -a ${diskImagePath}/${imageName} --copy-in rc.local:/etc/rc.d/
  virt-customize -a ${diskImagePath}/${imageName} --run-command 'chmod +x /etc/rc.d/rc.local'
  virt-customize -a ${diskImagePath}/${imageName} --run-command 'systemctl enable rc-local'


  # copy and inject key
  echo "Injecting ssh keys, and selinux relabelling"
  virt-customize -a ${diskImagePath}/${imageName} --ssh-inject root:file:${diskImagePath}/virt-local-key.pub
  virt-customize -a ${diskImagePath}/${imageName} --selinux-relabel
  virt-customize -a ${diskImagePath}/${imageName} --run-command 'mkdir -p /root/.ssh && chmod 700 /root/.ssh'
  virt-customize -a ${diskImagePath}/${imageName} --run-command 'dnf install -y python python-devel python-pip; update-alternatives --set python /usr/bin/python3;  update-alternatives --set python3 /usr/bin/python3; dnf clean all'
  virt-customize -a ${diskImagePath}/${imageName} --copy-in ${diskImagePath}/virt-local-key:/root/.ssh/
  virt-customize -a ${diskImagePath}/${imageName} --run-command 'mv /root/.ssh/virt-local-key /root/.ssh/id_rsa && chmod 600 /root/.ssh/id_rsa'

  # build metadata file
  imageName=${imageName} diskImagePath=${diskImagePath} bash build-metadata.sh 
fi 




