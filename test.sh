#!/bin/bash

source ./.env
source ./utils/global/nas_fct.sh

mount_nas

# if [ -z "$1" ]; then
# fusermount -u "$LOCAL_MOUNT"
# fi