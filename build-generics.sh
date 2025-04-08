#!/bin/bash 

echo "Rocky 9"
osinfo='rocky9' cloudImageURL='https://download.rockylinux.org/pub/rocky/9/images/x86_64/Rocky-9-GenericCloud-Base.latest.x86_64.qcow2' bash build-image.sh

echo "Rocky 8"
osinfo='rocky8' cloudImageURL='https://download.rockylinux.org/pub/rocky/8/images/x86_64/Rocky-8-GenericCloud-Base.latest.x86_64.qcow2' bash build-image.sh

echo "Debian 12"
osinfo='debian12' cloudImageURL='https://cdimage.debian.org/images/cloud/bookworm/latest/debian-12-genericcloud-amd64.qcow2' bash build-image.sh

