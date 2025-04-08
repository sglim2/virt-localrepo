#!/bin/bash

# Build virt-builder index.asc metadata entry for a named image with disk size in name.
# Example image name: rocky9-virt-localrepo-base-30G.qcow2

diskImagePath=${diskImagePath:='imgs'}
imagePathFull=${imagePathFull:='none'}
imageName=${imageName:='none'}
osinfo=${osinfo:='none'}

if [[ ${imageName} == 'none' ]]; then
  echo "Please specify 'imageName'"
  exit 1
fi

if [[ ${osinfo} == 'none' ]]; then
  echo "Please specify 'osinfo'"
  exit 1
fi

if [[ ${imagePathFull} == 'none' ]]; then
  echo "Please specify 'imagePathFull'"
  exit 1
fi

if [[ ! -d "${diskImagePath}" ]]; then
  echo "Directory ${diskImagePath} does not exist. Creating it."
  mkdir -p "${diskImagePath}"
fi

metadataFile="${diskImagePath}/index.asc"

cat >> "${metadataFile}" <<EOF

[${imageName}]
osinfo=${osinfo}
arch=x86_64
file=${imagePathFull##*/}
format=qcow2
size=$(stat -c%s "${imagePathFull}")
compressed_size=$(du -b "${imagePathFull}" | awk '{print $1}')
notes=Built on $(date +%Y-%m-%d)
EOF
