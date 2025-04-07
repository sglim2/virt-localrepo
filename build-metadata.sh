#!/bin/bash

# Build virt-builder index.asc metadata entry for a named image with disk size in name.
# Example image name: rocky9-virt-localrepo-base-30G.qcow2

diskImagePath=${diskImagePath:='imgs'}
imageName=${imageName:='none'}

if [[ ${imageName} == 'none' ]]; then
  echo "Please specify 'imageName'"
  exit 1
fi

metadataFile="${diskImagePath}/index.asc"

# Parse base name and size from imageName
# Example: rocky9-virt-localrepo-base-30G.qcow2
nameWithoutExt="${imageName%.qcow2}"
# Extract size suffix (e.g. 30G)
sizeSuffix=$(echo "$nameWithoutExt" | grep -oE '[0-9]+[GM]')
# Construct osinfo and [name] block using size
osShort=$(echo "$nameWithoutExt" | awk -F'-' '{print $1$2}' | tr '[:upper:]' '[:lower:]')
osinfo="${osShort}-${sizeSuffix}"

cat >> "${metadataFile}" <<EOF

[${osinfo}]
osinfo=${osinfo}
arch=x86_64
file=${imageName}
format=qcow2
size=$(stat -c%s "${diskImagePath}/${imageName}")
compressed_size=$(du -b "${diskImagePath}/${imageName}" | awk '{print $1}')
expand=/dev/sda3
notes=Built on $(date +%Y-%m-%d)
EOF
