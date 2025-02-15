#!/bin/bash

# VARIABLES PARAMETRES
PREFIXES=("" "$HOME/dev" "$HOME" "$HOME/dev/g404") # Ajouter un préfix dans le tableau pour tester un chemin supplémentaire
COPY_LOCATION="$HOME/Téléchargements/Contexte_LLM" # Dossier dans lequel sera copié tous les fichiers de contexte

# Fonctions
copy_files_with_path() { # Utilisation : copy_files_with_path "<extension>,<extension>" "<chemin_relatif>"; exemple : copy_files_with_path "js,css" "public"; ou : copy_files_with_path "php" "app/Http/Controllers"
    local EXTENSIONS=$(get_extension_regex "$1")
    local RELATIVE_PATH="$2"

    echo "Copie des fichiers *.$EXTENSIONS depuis $RELATIVE_PATH, avec la condition : $EXTENSIONS"
    echo "find "$PROJECT_PATH/$RELATIVE_PATH" \( $EXTENSIONS \) -type f"
    find "$PROJECT_PATH/$RELATIVE_PATH" \( $EXTENSIONS \) -type f | while read -r file; do
        echo "fichié trouvé : $file"
        # Calcul du chemin relatif
        rel_path=${file#$PROJECT_PATH/}
        
        # Récupération du nom du fichier sans le chemin
        filename=$(basename "$file")
        
        # Lecture du fichier et ajout du chemin relatif après <?php
        awk '/<\?/{print;print "// File location in project : '"$rel_path"'";next}1' "$file" > "$COPY_LOCATION/$filename"
    done
}
get_extension_regex(){
    IFS=',' read -ra EXT_ARRAY <<< "$1"

    # Construction de la condition find pour toutes les extensions
    find_condition=""
    for ext in "${EXT_ARRAY[@]}"; do
        if [ -z "$find_condition" ]; then
            find_condition="-name \"*.$ext\""
        else
            find_condition="$find_condition -o -name \"*.$ext\""
        fi
    done

    echo "$find_condition"
}

# Vérification des conditions d'utilisation
if [ -z "$1" ]; then
    echo "paramètre 1 manquant : Il faut le nom ou le répertoire du projet en premier paramètre."
    exit 1
fi

# Déclarations et formattage des variables 
PROJECT_PATH=""

# Nettoyage de $1 (on elève les / au début et à la fin)
PATH_SENT="${1%/}"
PATH_SENT="${PATH_SENT#/}"

# Recherche du chemin absolu du projet et préparation du répertoire de copie
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
# echo "Copie des contrôleurs"
# copy_files_with_path "php" "app/Http/Controllers"

declare -A FILES_TO_COPY=(
    ["controllers"]="php app/Http/Controllers"
    ["public_assets"]="css,js public"
    # ["public_assets2"]="js public"
)

for key in "${!FILES_TO_COPY[@]}"; do
    # Séparation des valeurs
    read -r extension path message <<< "${FILES_TO_COPY[$key]}"
    # Appel de la fonction avec les deux paramètres
    copy_files_with_path "$extension" "$path"
done