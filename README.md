
# Build a local virt repo, host on the local filesystem 

Build a local virt-builder repo. Good for customising and re-using VM images for use with libvirt/virt-install. 

Images are built with a pre-installed common ssh pub-key for root, and a common root password. The ssh key-pair is created during first image-build.

The resulting local virt-builder repo is particularly useful for building similar VMs for test environments where ssh keys are pre-configured.

This tool should be used for local development VMs and testing only.

# Getting started

Clone the virt-localrepo repository into your working directory:

```bash
git clone http://github.com/sglim2/virt-localrepo.git
cd virt-localrepo
```

Add a local virt-builder repository to config file:

```bash
mkdir -p ~/.config/virt-builder/repos.d/
cat >~/.config/virt-builder/repos.d/virt-localrepo.conf <<EOF 
[virt-localrepo]
uri=file://${PWD}/imgs/index.asc
proxy=off
EOF
```

The repo ```index.asc``` file will be created/appended after building the images.

To build a typical list of images, a wrapper script is provided:

```bash
#virt-builder --delete-cache # optional
bash ./build-generics.sh
```

This will build a set of images, and create the index.asc file. 

# Example repo usage 

A common ssh key is created and injected into the created images.

```bash
# list images
virt-builder --list
```

## Rocky9 example

```bash
# create a vm image
virt-builder rocky9 --format qcow2 --root-password password:virtpassword --size=30G -o rocky9-test.qcow2
# define a vm, using the new image..
virt-install --name rocky9-test --memory 8192 --noautoconsole --vcpus 6 --disk  rocky9-test.qcow2 --import --os-variant rocky9 --network bridge=virbr0
```

## Rocky8 example

```bash
# create a vm image
virt-builder rocky8 --format qcow2 --root-password password:virtpassword --size=30G -o rocky8-test.qcow2
# define a vm, using the new image..
virt-install --name rocky8-test --memory 8192 --noautoconsole --vcpus 6 --disk  rocky8-test.qcow2 --import --os-variant rocky8 --network bridge=virbr0
```



## Debian12 example

```bash
# create a vm image
virt-builder debian12 --format qcow2 --root-password password:virtpassword --size=30G -o debian12-test.qcow2
# define a vm, using the new image..
virt-install --name debian12-test --memory 8192 --noautoconsole --vcpus 6 --disk  debian12-test.qcow2 --import --os-variant debian12 --network bridge=virbr0
```


# Connecting via ssh

An ssh key-pair is created during the first image build. The same public key is injected into all subsequent image. Use this key for a handy ssh connection to the images, e.g. add the following to your ssh config file (assuming your libvirt bridge is on the network 192.168.122.1/24):

```bash
cat >>~/.ssh/config  <<EOF

Host 192.168.122.*
    User root
    IdentityFile ${PWD}/imgs/virt-local-key
    StrictHostKeyChecking no
    UserKnownHostsFile=/dev/null
    Identitiesonly yes

EOF


```
