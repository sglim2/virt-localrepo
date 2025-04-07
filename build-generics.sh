#!/bin/bash 

echo "Rocky 9"
imageName='rocky9-virt-localrepo-base.qcow2' cloudImageURL='https://download.rockylinux.org/pub/rocky/9/images/x86_64/Rocky-9-GenericCloud-Base.latest.x86_64.qcow2' imageSize=20G bash generic-rocky.sh

echo "Rocky 8"
imageName='rocky8-virt-localrepo-base.qcow2' cloudImageURL='https://download.rockylinux.org/pub/rocky/8/images/x86_64/Rocky-8-GenericCloud-Base.latest.x86_64.qcow2' imageSize=20G bash generic-rocky.sh

echo "Debian bookworm"
imageName='debian-bookworm-localrepo-base.qcow2' cloudImageURL='https://cdimage.debian.org/images/cloud/bookworm/latest/debian-12-genericcloud-amd64.qcow2' imageSize=20G bash generic-debian.sh

