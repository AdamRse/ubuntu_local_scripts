#!/bin/bash

# Set
script_path=$(readlink -f "$0")
script_dir=$(dirname "$script_path")

source $script_dir/.env
source $script_dir/utils/global/terminal-tools.fct.sh
source $script_dir/utils/global/nas_fct.sh
source $script_dir/utils/global/fct.sh

DEBUG_MODE=true

timout_sec="120"
[[ $timout_sec =~ ^[0-9]+$ ]] || eout "Le paramètre 'timout_sec' passé à la fonction en premier paramètre n'est pas un nombre : '${timout_sec}'"

mount_nas && sout "NAS MONTÉ"
ls -la "${NAS_MOUNT_POINT}/${NAS_NAME}"
echo "------------------------------"
unmount_nas && sout "NAS DÉMONTÉ"
ls -la "${NAS_MOUNT_POINT}/${NAS_NAME}"
