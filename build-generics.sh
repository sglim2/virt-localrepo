#!/bin/bash 


echo "Rocky 10"
osinfo='rocky10' cloudImageURL='https://download.rockylinux.org/pub/rocky/10/images/x86_64/Rocky-10-GenericCloud-Base.latest.x86_64.qcow2' bash build-image.sh

echo "Rocky 9"
osinfo='rocky9' cloudImageURL='https://download.rockylinux.org/pub/rocky/9/images/x86_64/Rocky-9-GenericCloud-Base.latest.x86_64.qcow2' bash build-image.sh

echo "Debian 13"
osinfo='debian13' cloudImageURL='https://cdimage.debian.org/images/cloud/bookworm/latest/debian-13-genericcloud-amd64.qcow2' bash build-image.sh

echo "Debian 12"
osinfo='debian12' cloudImageURL='https://cdimage.debian.org/images/cloud/bookworm/latest/debian-12-genericcloud-amd64.qcow2' bash build-image.sh

