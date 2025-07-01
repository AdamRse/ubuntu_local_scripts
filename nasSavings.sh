#!/bin/bash

source .env
source ./utils/global/fct.sh
source ./utils/global/nas_fct.sh

mount_nas || fout "Impossible de monter le NAS, arrêt du programme."

# Vérifier que le point de montage existe
if [ ! -d "$NAS_MOUNT_POINT" ]; then
    fout "Le point de montage $NAS_MOUNT_POINT n'existe pas"
fi

# Traiter chaque paire de backup
for pair in "${BACKUP_PAIRS[@]}"; do
    # Séparer la source et la destination
    IFS=":" read -r source_pattern dest_dir <<< "$pair"
    
    # Supprimer les espaces en début/fin si nécessaire
    source_pattern=$(echo "$source_pattern" | xargs)
    dest_dir=$(echo "$dest_dir" | xargs)
    
    # Construire le chemin de destination complet
    full_dest="${NAS_MOUNT_POINT%/}/${dest_dir%/}"
    
    # Créer le répertoire de destination si nécessaire
    mkdir -p "$full_dest" || fout "Impossible de créer le répertoire $full_dest"
    
    # Copier les fichiers
    echo "Copie de $source_pattern vers $full_dest"
    if [[ $source_pattern == *'**'* ]]; then
        # Cas du globbing récursif
        shopt -s globstar
        for file in $source_pattern; do
            [ -e "$file" ] || continue
            cp -v "$file" "$full_dest/"
        done
        shopt -u globstar
    else
        # Cas normal
        for file in $source_pattern; do
            [ -e "$file" ] || continue
            cp -v "$file" "$full_dest/"
        done
    fi
done

echo "Sauvegarde terminée avec succès"
