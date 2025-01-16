#!/bin/bash 

# template example
#
# [name]
# osinfo=rocky9
# arch=x86_64
# file=Rocky-9-GenericCloud-Base.latest.x86_64.qcow2
# format=qcow2
# size=2024803456
# compressed_size=587202560
# expand=/dev/sda3
# notes=Built on $(date +%Y-%m-%d)


diskImagePath=${diskImagePath:='imgs'}
imageName=${imageName:='none'}

if [[ ${imageName} == 'none' ]] ; then
  echo "Please specify 'imageName'"
  exit 1
fi

metadataFile="${diskImagePath}/index.asc"


cat >> ${metadataFile} <<EOF

[$(echo ${imageName} | awk -F'-' '{print $1$2}' | tr '[:upper:]' '[:lower:]')-local]
osinfo=$(echo ${imageName} | awk -F'-' '{print $1$2}' | tr '[:upper:]' '[:lower:]')
arch=x86_64
file=${imageName}
format=qcow2
size=$(stat -c%s ${diskImagePath}/${imageName})
compressed_size=$(du -b ${diskImagePath}/${imageName} | awk '{print $1}')
expand=/dev/sda3
notes=Built on $(date +%Y-%m-%d)
EOF

