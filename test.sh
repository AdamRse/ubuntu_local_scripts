#!/bin/bash

# Set
SCRIPT_PATH=$(readlink -f "$0")
SCRIPT_DIR=$(dirname "${SCRIPT_PATH}")

source "${SCRIPT_DIR}/.env"
source "${SCRIPT_DIR}/utils/global/terminal-tools.fct.sh"
source "${SCRIPT_DIR}/utils/global/nas_fct.sh"
source "${SCRIPT_DIR}/utils/global/fct.sh"

DEBUG_MODE=true
