
# Build a local virt repo, host on the local filesystem 

## Why?

  * The whole process is designed for user-space - no root required.
  * It's fast (once built), and customisable.
  * Easily deploy VMs using image from the local virt repo.
  * A single point of reference for building various OS images
  * a common ssh key to access all local VM images

# Getting started

Clone the virt-localrepo repository into your working directory:

```
git clone http://github.com/sglim2/virt-localrepo.git
cd virt-localrepo
```

Add a local virt-builder repository to config file:

```   
mkdir -p ~/.config/virt-builder/repos.d/
VIRTLOCALREPO=${pwd}
cat >~/.config/virt-builder/repos.d/virt-localrepo.conf <<EOF 
[virt-localrepo]
uri=file:///${VIRTLOCALREPO}/imgs/index.asc
proxy=off
EOF
```

The index.asc file will be created after building the images.


To build a typical list of images, a wrapper script is provided:
```
#virt-builder --delete-cache # optional
bash ./build-generics.sh
```

This will build a set of images, and create the index.asc file. 

# example repo usage 

A common ssh key is created and injected into the created images.

```
# list images
virt-builder --list
```

```
# create a vm image
# note, this doesn't resize the image
virt-builder rocky9-base --format qcow2 --root-password password:virtpassword -o rocky9-base.qcow2

## to resize the image:
#qemu-img resize rocky9-base.qcow2 30G
## seems to be a bug in virt-resize, and the below doesn't work
#virt-resize --expand /dev/sda5 imgs/rocky9-base.qcow2 rocky9-base.qcow2
## if needed, once the vm is running, resize the partition manually:
##  $ parted -s -a optimal /dev/vda5 "resizepart 5 100%"
##  $ xfs_growfs /dev/vda5


# define a vm, using the above image..
virt-install --name rocky9-base --memory 8192 --noautoconsole --vcpus 6 --disk  rocky9-base.qcow2 --import --os-variant rocky9 --network bridge=virbr0
```

# local cache

