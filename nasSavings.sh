#!/bin/bash

# Set
script_path=$(readlink -f "$0")
script_dir=$(dirname "$script_path")

source $script_dir/.env
source $script_dir/utils/global/nas_fct.sh
source $script_dir/utils/global/fct.sh

unmount_nas
mount_nas || fout "Impossible de monter le NAS, arrêt du programme."

echo "---------------------NAS SAVINGS-------------------------"
# Traiter chaque paire de backup
for pair in "${BACKUP_PAIRS[@]}"; do
    # Séparer la source et la destination
    IFS=":" read -r source_pattern dest_dir <<< "$pair"
    
    # Supprimer les espaces en début/fin si nécessaire
    source_pattern=$(echo "$source_pattern" | xargs)
    dest_dir=$(echo "$dest_dir" | xargs)

    #On enlève le 1er "/"
    if [[ "${dest_dir:0:1}" == "/" ]]; then
        dest_dir="${dest_dir:1}"
    fi
    
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
