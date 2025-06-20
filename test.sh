#!/bin/bash

source ./.env
source ./utils/global/nas_fct.sh

if [ -n "$1" ]; then
    unmount_nas
else
    mount_nas
fi