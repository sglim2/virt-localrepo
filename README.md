
# Build a local virt repo, host on the local filesystem 

Build a local virt-builder repo. Good for customising and re-using VM images for use with libvirt/virt-install. 

Images are built with a pre-installed common ssh pub-key for root, and a common root password. The ssh key-pair is created during first image-build.

The resulting local virt-builder repo is particularly useful for building virtual test environments for clusters services, where VM disk sizes and ssh keys are pre-configured.

This tool is designed for local development and testing only.

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

The repo ```index.asc``` file will be created/appended after building the images.

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

## Rocky9 example

```
# create a vm image
virt-builder rocky9virt-20G --format qcow2 --root-password password:virtpassword -o rocky9-base-2G.qcow2
```

```
# define a vm, using the new image..
virt-install --name rocky9-base-20G --memory 8192 --noautoconsole --vcpus 6 --disk  rocky9-base-20G.qcow2 --import --os-variant rocky9 --network bridge=virbr0
```

## Rocky8 example

```
# create a vm image
virt-builder rocky8virt-20G --format qcow2 --root-password password:virtpassword -o rocky8-base-20G.qcow2
```

```
# define a vm, using the new image..
virt-install --name rocky8-base-20G --memory 8192 --noautoconsole --vcpus 6 --disk  rocky8-base-20G.qcow2 --import --os-variant rocky8 --network bridge=virbr0
```



## Debian12 example

```
# create a vm image
virt-builder debianbookworm-20G --format qcow2 --root-password password:virtpassword -o debianbookworm-base-20G.qcow2
```

```
# define a vm, using the new image..
virt-install --name debianbookworm-base-20G --memory 8192 --noautoconsole --vcpus 6 --disk  debianbookworm-base-20G.qcow2 --import --os-variant debian12 --network bridge=virbr0
```
