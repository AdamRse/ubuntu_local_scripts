#!/bin/bash

# Set
script_path=$(readlink -f "$0")
script_dir=$(dirname "$script_path")

source $script_dir/.env
source $script_dir/utils/global/nas_fct.sh
source $script_dir/utils/global/fct.sh

disable_sleep
sleep 1
enable_sleep
