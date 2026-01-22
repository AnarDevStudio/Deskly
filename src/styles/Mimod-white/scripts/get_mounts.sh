#!/bin/bash
PATHS=("/home")
NAMES=("home")
MOUNTED_PATHS=$(findmnt -rno TARGET,SOURCE | grep -E '^/media/|^/mnt/|^/run/media/' | grep -v '^/mnt$')
while IFS=' ' read -r path_item source_item; do
if [ ${#PATHS[@]} -ge 4 ]; then
break
fi
if [[ -n "$path_item" ]]; then
if ! [[ " ${PATHS[*]} " =~ " ${path_item} " ]]; then
name_full="${path_item##*/}"
name_full=$(echo "$name_full" | sed 's/\\x20/ /g')
if [[ -z "$name_full" ]]; then
name_full="${source_item##*/}"
fi
NAMES+=("${name_full:0:5}")
PATHS+=("$path_item")
PATHS[-1]=$(echo "${PATHS[-1]}" | sed 's/\\x20/ /g')
fi
fi
done <<< "$MOUNTED_PATHS"
while [ ${#PATHS[@]} -lt 4 ]; do
PATHS+=("/dev/null")
NAMES+=("N/A")
done
P8=${PATHS[0]} ; N4=${NAMES[0]}
P1=${PATHS[1]} ; N5=${NAMES[1]}
P2=${PATHS[2]} ; N6=${NAMES[2]}
P3=${PATHS[3]} ; N7=${NAMES[3]}
echo "${P8}"
echo "${P1}"
echo "${P2}"
echo "${P3}"
echo "${N4}"
echo "${N5}"
echo "${N6}"
echo "${N7}"
exit 0
