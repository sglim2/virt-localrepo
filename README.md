
# Build a local virt repo, host on the local filesystem 

Build a local virt-builder repo. Good for customising and re-usiing VM images for use with libvirt/virt-install.

# Getting started

Clone the virt-localrepo repository into your working directory:

```
git clone http://github.com/sglim2/virt-localrepo.git
cd virt-localrepo
```

Add a local virt-builder repository to config file:

```   
mkdir -p ~/.config/virt-builder/repos.d/
cat >~/.config/virt-builder/repos.d/virt-localrepo.conf <<EOF 
[virt-localrepo]
uri=file://${PWD}/imgs/index.asc
proxy=off
EOF
```

The repo ```index.asc``` file will be created after building the images.

To build a typical list of images, a wrapper script is provided:

```
#virt-builder --delete-cache # optional
bash ./build-generics.sh
```

This will build a set of images, and create the index.asc file. 

# Example repo usage 

A common ssh key is created and injected into the created images.

```
# list images
virt-builder --list
```

```
# create a vm image
virt-builder rocky9virt-local --format qcow2 --root-password password:virtpassword --size 30G -o rocky9-base.qcow2
```

```
# define a vm, using the new image..
virt-install --name rocky9-base --memory 8192 --noautoconsole --vcpus 6 --disk  rocky9-base.qcow2 --import --os-variant rocky9 --network bridge=virbr0
```


