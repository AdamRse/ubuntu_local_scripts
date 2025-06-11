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

# SOURCES
source ./.env
source ./utils/global/fct.sh
source ./utils/screenManager/screenManagerSetFcts.sh # Dépendance à .env
source ./utils/screenManager/screenManagerChecks.sh # Dépendance à .env, screenManagerSetFcts.sh 

echo "TEST"
save_config_file
echo $(read_config_file)