#!/bin/bash

SCRIPT_PATH=$(readlink -f "$0")
SCRIPT_DIR=$(dirname "$SCRIPT_PATH")
COMMAND_NAME="locs-nas-mount"
MOUNT=""

source "$SCRIPT_DIR/utils/requirments/nas.req.sh"
source "$SCRIPT_DIR/.env"
source "$SCRIPT_DIR/utils/global/terminal-tools.fct.sh"
source "$SCRIPT_DIR/utils/global/nas_fct.sh"
source "$SCRIPT_DIR/utils/global/fct.sh"

source "$SCRIPT_DIR/utils/argument_set/nas-mount.getopt.sh"

if [ $MOUNT = true ]; then
    lout "Montage du serveur NAS"
    mount_nas
elif [ $MOUNT = false ]; then
    lout "Démontage du serveur NAS"
    unmount_nas
else
    if is_nas_mounted "$(clean_path_variable "absolute" "${NAS_MOUNT_POINT}")"; then
        lout "Le NAS était monté : Démontage du serveur NAS"
        unmount_nas
    else
        lout "Le NAS n'était pas monté : Montage du serveur NAS"
        mount_nas
    fi
fi