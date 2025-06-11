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
source ./utils/screenManagerFcts.sh
source ./utils/fct.sh

