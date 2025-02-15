#!/bin/bash

# VARIABLES PARAMETRES
PREFIXES=("" "$HOME/dev" "$HOME" "$HOME/dev/g404") # Ajouter un préfix dans le tableau pour tester un chemin supplémentaire
COPY_LOCATION="$HOME/Téléchargements/Contexte_LLM" # Dossier dans lequel sera copié tous les fichiers de contexte

# Vérification du repo
if [ -z "$1" ]; then
    echo "paramètre 1 manquant : Il faut le nom ou le répertoire du projet en premier paramètre."
    exit 1
fi

# Déclarations et formattage des variables 
PROJECT_PATH=""

# Nettoyage de $1 (on elève les / au début et à la fin)
PATH_SENT="${1%/}"
PATH_SENT="${PATH_SENT#/}"

# Recherche du chemin absolu du projet
for PREFIX in "${PREFIXES[@]}"; do
    TEST_PATH="$PREFIX/$PATH_SENT"
    if [ -d "$TEST_PATH" ] && [ -f "$TEST_PATH/artisan" ] && [ -f "$TEST_PATH/composer.json" ] && [ -d "$TEST_PATH/app" ]; then
        PROJECT_PATH="$TEST_PATH"
        break
    fi
done

if [ -z "$PROJECT_PATH" ]; then
    echo "Impossible de trouver le projet $1"
    exit 1
fi
echo "Projet Laravel trouvé : dans $PROJECT_PATH"

if [ -d "$COPY_LOCATION" ]; then
    echo "Nettoyage du répertoire de contexte"
    rm -rf "$COPY_LOCATION"/*
else
    echo "Création du répertoire de contexte"
    mkdir -p "$COPY_LOCATION"
fi

# Copie et modification des contrôleurs
echo "Copie des contrôleurs"
# find "$PROJECT_PATH/app/Http/Controllers" -name "*.php" -type f | while read -r file; do 
#     # Calcul du chemin relatif
#     rel_path=${file#$PROJECT_PATH/}
    
#     # Récupération du nom du fichier sans le chemin
#     filename=$(basename "$file")
    
#     # Lecture du fichier et ajout du chemin relatif après <?php
#     awk '/<\?/{print;print "// Chemin relatif: '"$rel_path"'";next}1' "$file" > "$COPY_LOCATION/$filename"
# done

copy_files_with_path() { # Utilisation : copy_files_with_path "<extension>" "<chemin_relatif>"
    local EXTENSION="$1"
    local RELATIVE_PATH="$2"
    
    echo "Copie des fichiers *.$EXTENSION depuis $RELATIVE_PATH"
    find "$PROJECT_PATH/$RELATIVE_PATH" -name "*.$EXTENSION" -type f | while read -r file; do
        # Calcul du chemin relatif
        rel_path=${file#$PROJECT_PATH/}
        
        # Récupération du nom du fichier sans le chemin
        filename=$(basename "$file")
        
        # Lecture du fichier et ajout du chemin relatif après <?php
        awk '/<\?/{print;print "// File location in project : '"$rel_path"'";next}1' "$file" > "$COPY_LOCATION/$filename"
    done
}

# Copie des différents types de fichiers
copy_files_with_path "php" "app/Http/Controllers"