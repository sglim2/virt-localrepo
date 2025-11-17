#!/bin/bash

# Build virt-builder index.asc metadata entry for a named image with disk size in name.
# Probes the image to determine the root (/) partition for the expand= line.

diskImagePath=${diskImagePath:='imgs'}
imagePathFull=${imagePathFull:='none'}
osinfo=${osinfo:='none'}

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

# Detect root partition using virt-inspector
echo "Probing root filesystem partition..."
root_partition=$(virt-inspector --format=qcow2 --no-applications -a "${imagePathFull}" | xmllint --xpath 'string(//mountpoint[text()="/"]/@dev)' -)

if [[ -z "$root_partition" ]]; then
  echo "Warning: Could not determine root partition. 'expand=' entry will be omitted."
else
  echo "Root partition detected: $root_partition"
fi

# Append metadata block
echo "Writing metadata for ${osinfo}..."

cat >> "${metadataFile}" <<EOF

[${osinfo}]
osinfo=${osinfo}
arch=x86_64
file=${imagePathFull##*/}
format=qcow2
size=$(stat -c%s "${imagePathFull}")
compressed_size=$(du -b "${imagePathFull}" | awk '{print $1}')
EOF

# Add expand line if root partition was found
if [[ -n "$root_partition" ]]; then
  echo "expand=$root_partition" >> "${metadataFile}"
fi

# Add build date note
echo "notes=Built on $(date +%Y-%m-%d)" >> "${metadataFile}"


