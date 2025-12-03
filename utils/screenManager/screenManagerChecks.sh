#!/bin/bash
#
# Dépendance : .env, ./utils/screenManager/screenManagerFcts.sh

# CHECKS
# Accès répertoire de config
if  [ ! -d "$CONFIG_DIR" ]; then
    mkdir -p "$CONFIG_DIR" || fnout "Impossible de créer le répertoire de configuration dans $CONFIG_DIR. Vérifiez les droits d'écriture ou changez la clé \$CONFIG_DIR dans le .env"
else
    if [ ! -w "$CONFIG_DIR" ]; then
        fnout "Droits d'écriture requis pour $CONFIG_DIR. Vérifiez les droits d'écriture ou changez la clé \$CONFIG_DIR dans le .env"
    fi
fi
# Accès fichiers de config
if [ ! -f "$pathfile_screenList" ] || [ ! -w "$pathfile_screenList" ] || [ ! -r "$pathfile_screenList" ]; then
    fnout "Le fichier '$pathfile_screenList' n'est pas accessible en écriture"
fi