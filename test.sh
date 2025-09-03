#!/bin/bash


# if [ -n "$1" ]; then
#     unmount_nas
# else
#     mount_nas
# fi
script_dir=$(dirname "$0")

source $script_dir/.env
source $script_dir/utils/global/nas_fct.sh
source $script_dir/utils/global/fct.sh

lout "Test de lout"