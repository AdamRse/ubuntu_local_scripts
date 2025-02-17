#!/bin/bash

# VARIABLES PARAMETRES
PREFIXES=("" "$HOME/dev" "$HOME" "$HOME/dev/g404") # Ajouter un préfix dans le tableau pour tester un chemin supplémentaire
COPY_LOCATION="$HOME/Téléchargements/Contexte_LLM" # Dossier dans lequel sera copié tous les fichiers de contexte
FILES_TO_COLLECT=( # Tableau de string qui contient les extensions et répertoires à collecter. ex : "php resources/views" va collecter tous le fichiers .php dans le répertoire resources/views du projet (récursivement)
    "php app"
    "php resources/views"
    "css public"
    "web.php routes"
    "php database/migrations"
    "php database/seeders"
)

# Fonctions
copy_files_with_path() { # Utilisation : copy_files_with_path "<extension>,<extension>" "<chemin_relatif>"; exemple : copy_files_with_path "js,css" "public"; ou : copy_files_with_path "php" "app/Http/Controllers"
    local EXTENSIONS="$1"
    local RELATIVE_PATH="$2"
    echo -e "-----------\nRecherche et copie des fichiers depuis $RELATIVE_PATH pour extensions: $EXTENSIONS"
    
    # Création du tableau d'extensions
    IFS=',' read -ra EXT_ARRAY <<< "$EXTENSIONS"
    
    # Construction de la condition find (recherche des extensions)
    local find_params=()
    local first=true
    
    for ext in "${EXT_ARRAY[@]}"; do
        if $first; then
            find_params+=(-name "*$ext")
            first=false
        else
            find_params+=(-o -name "*$ext")
        fi
    done
    
    find "$PROJECT_PATH/$RELATIVE_PATH" \( "${find_params[@]}" \) -type f | while read -r file; do
        echo "$file"
        # Calcul du chemin relatif
        rel_path=${file#$PROJECT_PATH/}
        # Récupération du nom du fichier sans le chemin
        filename=$(basename "$file")

        if [[ "$filename" == *.blade.php ]]; then
            # Pour les fichiers Blade
            echo -e "{{-- File location in project : $rel_path --}}\n\n" > "$COPY_LOCATION/$filename"
            cat "$file" >> "$COPY_LOCATION/$filename"
        elif [[ "$filename" == *.php ]]; then
            # Pour les fichiers PHP standards
            awk '/<\?/{print;print "// File location in project : '"$rel_path"'\n\n";next}1' "$file" > "$COPY_LOCATION/$filename"
        elif [[ "$filename" == *.js ]]; then
            # Pour les fichiers JavaScript
            echo -e "// File location in project : $rel_path\n\n" > "$COPY_LOCATION/$filename"
            cat "$file" >> "$COPY_LOCATION/$filename"
        elif [[ "$filename" == *.css ]]; then
            # Pour les fichiers CSS
            echo -e "/*\n* File location in project : $rel_path\n*/\n\n" > "$COPY_LOCATION/$filename"
            cat "$file" >> "$COPY_LOCATION/$filename"
        else
            # Pour tous les autres types de fichiers
            echo -e "# File location in project : $rel_path\n\n" > "$COPY_LOCATION/$filename"
            cat "$file" >> "$COPY_LOCATION/$filename"
        fi
    done
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

# On parcourt le tableau FILES_TO_COLLECT en extrayant l'extension à rechercher, et le chemin où chercher
for entry in "${FILES_TO_COLLECT[@]}"; do
    read -r extension path <<< "$entry"
    copy_files_with_path "$extension" "$path"
done

echo -e "++++++++\nTerminé !"