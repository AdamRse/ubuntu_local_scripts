#!/bin/bash

# Set
script_path=$(readlink -f "$0")
script_dir=$(dirname "$script_path")

source $script_dir/.env
source $script_dir/utils/global/nas_fct.sh
source $script_dir/utils/global/fct.sh

# if [ -n "$1" ]; then
#     unmount_nas
# else
#     mount_nas
# fi
if [ -n "$1" ]; then
    if [ "$1" == "0" ]; then
        unmount_nas
    elif [ "$1" == "1" ]; then
        mount_nas
    else
        echo "Paramètre '$1' non interprété. Envoyez 0 (déconnecter) ou 1 (monter le NAS).";
    fi
else
    echo "Paramètre 0 (déconnecter) ou 1 (monter le NAS) obligatoire.";
fi
