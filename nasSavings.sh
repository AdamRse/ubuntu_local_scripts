#!/bin/bash

source .env
source ./utils/global/nas_fct.sh

mount_nas || fout "Impossible de monter le NAS, arrêt du programme."

# a faire la copie