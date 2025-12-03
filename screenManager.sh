#!/bin/bash
#===============================================================================
# Nom:         screenManager.sh
# Description: Permet de configurer plusieurs modes d'affichage
#              Fonctionne sur Linux, testé avec ubuntu
# Auteur:      Adam Rousselle
# Version:     0.1
# Date:        2025-06-11
# Usage:       ./screenManager.sh <mode>
#===============================================================================

# CONFIG
set -e
script_path=$(readlink -f "$0")
script_dir=$(dirname "$script_path")

source "$script_dir/.env"
source "$script_dir/utils/global/fct.sh"

# SOURCES
source "$script_dir/.env"
source "$script_dir/utils/global/fct.sh"
source "$script_dir/utils/screenManager/screenManagerSetFcts.sh" # Dépendance à .env
source "$script_dir/utils/screenManager/screenManagerChecks.sh" # Dépendance à .env, screenManagerSetFcts.sh 

echo "TEST"
save_config_file
echo $(read_config_file)