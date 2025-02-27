#!/bin/bash

# Activer globstar pour utiliser les motifs ** (récursifs)
shopt -s globstar
# Activer nullglob pour que les motifs sans correspondance deviennent des chaînes vides
shopt -s nullglob

# VARIABLES PARAMETRES
PREFIXES=("" "$HOME/dev" "$HOME" "$HOME/dev/g404") # Préfixes de chemin possibles pour le projet
COPY_LOCATION="$HOME/Téléchargements/Contexte_LLM" # Dossier dans lequel sera copié tous les fichiers de contexte
# Fichier de configuration par défaut si aucun fichier .context n'est trouvé
FILES_TO_COLLECT=(
    "**/*"
)
FILES_TO_IGNORE=(
    # Note: .context/context-config.json est ignoré automatiquement, pas besoin de l'ajouter ici
)

INIT_MODE=false

# Parcourir tous les arguments après le premier (qui est le chemin du projet)
for arg in "${@:2}"; do
    case "$arg" in
        -i|--init)
            INIT_MODE=true
            ;;
        *)
            echo "Option non reconnue: $arg"
            ;;
    esac
done

# Vérifie si un fichier doit être ignoré en le comparant aux motifs d'exclusion
should_ignore_file() {
    local rel_path="$1"
    
    # Toujours ignorer le fichier de configuration lui-même
    if [[ "$rel_path" == ".context/context-config.json" ]]; then
        return 0 # true, ignorer le fichier
    fi
    
    for ignore_pattern in "${FILES_TO_IGNORE[@]}"; do
        # Comparaison avec le motif d'exclusion
        if [[ "$rel_path" == $ignore_pattern ]]; then
            return 0 # true, ignorer le fichier
        fi
    done
    
    return 1 # false, ne pas ignorer le fichier
}

# Copie un fichier vers le répertoire de destination avec le format approprié
copy_file() {
    local file="$1"
    local rel_path="${file#$PROJECT_PATH/}"
    
    echo -e "\e[32mCopie: $rel_path\e[0m"
    # Récupération du nom du fichier sans le chemin
    filename=$(basename "$file")
    
    if [[ "$rel_path" == .context/* ]]; then
        # Pour les fichiers du répertoire .context, copie directe sans ajout de commentaire
        cp "$file" "$COPY_LOCATION/$filename"
    elif [[ "$filename" == *.blade.php ]]; then
        # Pour les fichiers Blade
        echo -e "{{-- File location in project : $rel_path --}}" > "$COPY_LOCATION/$filename"
        cat "$file" >> "$COPY_LOCATION/$filename"
    elif [[ "$filename" == *.php ]]; then
        # Pour les fichiers PHP standards
        awk '/<\?/{print;print "// File location in project : '"$rel_path"'";next}1' "$file" > "$COPY_LOCATION/$filename"
    elif [[ "$filename" == *.js ]]; then
        # Pour les fichiers JavaScript
        echo -e "// File location in project : $rel_path" > "$COPY_LOCATION/$filename"
        cat "$file" >> "$COPY_LOCATION/$filename"
    elif [[ "$filename" == *.css ]]; then
        # Pour les fichiers CSS
        echo -e "/*\n* File location in project : $rel_path\n*/" > "$COPY_LOCATION/$filename"
        cat "$file" >> "$COPY_LOCATION/$filename"
    else
        # Pour tous les autres types de fichiers
        echo -e "# File location in project : $rel_path" > "$COPY_LOCATION/$filename"
        cat "$file" >> "$COPY_LOCATION/$filename"
    fi
}

# Collecte les fichiers en utilisant les motifs glob
collect_files() {
    # Mémoriser le répertoire de travail actuel
    local current_dir=$(pwd)
    
    # Se déplacer dans le répertoire du projet pour que les motifs glob fonctionnent correctement
    cd "$PROJECT_PATH"
    
    # Parcourir tous les motifs à collecter
    for pattern in "${FILES_TO_COLLECT[@]}"; do
        echo -e "-----------\nRecherche avec le motif: $pattern"
        
        # Utiliser directement le motif glob de bash
        for file in $pattern; do
            # Vérifier si c'est un fichier régulier
            if [[ -f "$file" ]]; then
                # Vérifier si le fichier doit être ignoré
                if should_ignore_file "$file"; then
                    echo -e "\e[33mIgnoré: $file\e[0m"
                else
                    copy_file "$PROJECT_PATH/$file"
                fi
            fi
        done
    done
    
    # Revenir au répertoire de travail initial
    cd "$current_dir"
}

# Fonction pour charger la configuration depuis le fichier .context/context-config.json
load_context_config() {
    local config_file="$PROJECT_PATH/.context/context-config.json"
    
    # Vérification si le fichier de configuration existe
    if [ -f "$config_file" ]; then
        echo "Fichier de configuration trouvé: $config_file"
        
        # Vérifier si jq est installé
        if ! command -v jq >/dev/null 2>&1; then
            echo "Erreur: L'utilitaire 'jq' n'est pas installé mais est requis pour analyser le fichier de configuration."
            echo "Installez-le avec 'sudo apt install jq'."
            exit 1
        fi
        
        # Vérifier que le fichier JSON est valide
        if ! jq empty "$config_file" 2>/dev/null; then
            echo -e "\e[31mErreur: Le fichier de configuration n'est pas un JSON valide.\e[0m"
            echo "Vérifiez la syntaxe de votre fichier: $config_file"
            exit 1
        fi
        
        # Vérifier que la structure est correcte (files_to_collect doit exister)
        if ! jq -e '.files_to_collect' "$config_file" >/dev/null 2>&1; then
            echo -e "\e[31mErreur: Le fichier de configuration ne contient pas la clé obligatoire 'files_to_collect'.\e[0m"
            echo "Assurez-vous que votre fichier contient au moins un tableau 'files_to_collect'."
            exit 1
        fi
        
        echo "Utilisation du fichier de configuration: $config_file"
        
        # Lecture des fichiers à collecter
        mapfile -t FILES_TO_COLLECT < <(jq -r '.files_to_collect[]' "$config_file")
        
        # Lecture des fichiers à ignorer (si présents)
        if jq -e '.files_to_ignore' "$config_file" >/dev/null 2>&1; then
            mapfile -t FILES_TO_IGNORE < <(jq -r '.files_to_ignore[]' "$config_file")
        fi
        
        # On peut aussi charger d'autres configurations si nécessaire
        if jq -e '.copy_location' "$config_file" >/dev/null 2>&1; then
            COPY_LOCATION=$(jq -r '.copy_location' "$config_file")
            # Expansion de la variable $HOME si présente
            COPY_LOCATION="${COPY_LOCATION//\$HOME/$HOME}"
        fi
        
        return 0
    else
        echo "Aucun fichier de configuration trouvé. Utilisation de la configuration par défaut."
        set_default_collect_type
    fi
    return 1
}

set_default_collect_type() {
    if [ -f "$PROJECT_PATH/artisan" ] && [ -d "$PROJECT_PATH/app" ]; then # Laravel détecté
        echo "Application Laravel trouvée, application du contexte par défaut pour laravel"
        FILES_TO_COLLECT=(
            "app/**/*.php"
            "database/**/*.php"
            "routes/api.php"
            "routes/web.php"
            "config/**/*.php"
            "resources/**/*.php"
            "resources/**/*.js"
            "resources/**/*.css"
            ".context/**/*"
        )
        FILES_TO_IGNORE=(
            "database/migrations/*cache_table.php"
            "app/Http/Controllers/Controller.php"
            "resources/views/components/**/*"
        )
    else
        echo "Application de type inconnu, tous les fichiers du projet seront ajoutés au contexte"
    fi
}

# Nouvelle fonction pour initialiser l'architecture .context
initialize_context_structure() {
    local context_dir="$PROJECT_PATH/.context"
    
    echo "Initialisation de la structure .context pour le projet: $PROJECT_PATH"
    
    # Création du dossier .context s'il n'existe pas
    if [ ! -d "$context_dir" ]; then
        echo "Création du dossier .context"
        mkdir -p "$context_dir"
    fi
    
    # Création du fichier instructions.txt
    if [ ! -f "$context_dir/instructions.txt" ]; then
        echo "Création du fichier instructions.txt"
        cat > "$context_dir/instructions.txt" << EOL
# Instructions pour le contexte LLM
Ce fichier contient des instructions sur la façon dont le code du projet devrait être interprété.
Vous pouvez ajouter ici des informations pertinentes pour le LLM.
EOL
    fi
    
    # Création du fichier objectif.txt
    if [ ! -f "$context_dir/objectif.txt" ]; then
        echo "Création du fichier objectif.txt"
        cat > "$context_dir/objectif.txt" << EOL
# Objectif du projet
Décrivez ici l'objectif principal du projet et les fonctionnalités clés.
Ces informations aideront le LLM à comprendre le contexte global.
EOL
    fi
    
    # Création du fichier context-config.json avec les valeurs par défaut
    if [ ! -f "$context_dir/context-config.json" ]; then
        echo "Création du fichier context-config.json"
        echo "{" > "$context_dir/context-config.json"
        echo "    \"files_to_collect\": [" >> "$context_dir/context-config.json"
        
        # Ajouter chaque pattern de collecte
        for (( i=0; i<${#FILES_TO_COLLECT[@]}; i++ )); do
            if [ $i -eq $(( ${#FILES_TO_COLLECT[@]} - 1 )) ]; then
                echo "        \"${FILES_TO_COLLECT[$i]}\"" >> "$context_dir/context-config.json"
            else
                echo "        \"${FILES_TO_COLLECT[$i]}\"," >> "$context_dir/context-config.json"
            fi
        done
        
        echo "    ]," >> "$context_dir/context-config.json"
        echo "    \"files_to_ignore\": [" >> "$context_dir/context-config.json"
        
        # Ajouter chaque pattern d'ignorance
        for (( i=0; i<${#FILES_TO_IGNORE[@]}; i++ )); do
            if [ $i -eq $(( ${#FILES_TO_IGNORE[@]} - 1 )) ]; then
                echo "        \"${FILES_TO_IGNORE[$i]}\"" >> "$context_dir/context-config.json"
            else
                echo "        \"${FILES_TO_IGNORE[$i]}\"," >> "$context_dir/context-config.json"
            fi
        done
        
        echo "    ]," >> "$context_dir/context-config.json"
        echo "    \"copy_location\": \"$COPY_LOCATION\"" >> "$context_dir/context-config.json"
        echo "}" >> "$context_dir/context-config.json"
    fi
    
    echo -e "\e[1;32mInitialisation terminée !\e[0m"
    echo "Structure .context créée dans: $context_dir"
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
    if [ -d "$TEST_PATH" ]; then
        PROJECT_PATH="$TEST_PATH"
        break
    fi
done

if [ -z "$PROJECT_PATH" ]; then
    echo "Impossible de trouver le projet $1"
    exit 1
fi
echo "Projet trouvé : dans $PROJECT_PATH"

# Chargement de la configuration spécifique au projet
load_context_config


if [ "$INIT_MODE" = true ]; then
    echo "Initialisation du projet"
    initialize_context_structure
    exit 0
fi


# Préparation du dossier de destination
if [ -d "$COPY_LOCATION" ]; then
    echo "Nettoyage du répertoire de contexte"
    rm -rf "$COPY_LOCATION"/*
else
    echo "Création du répertoire de contexte"
    mkdir -p "$COPY_LOCATION"
fi

# Collecte des fichiers selon les motifs définis
collect_files

echo -e "\e[1;32m++++++++\nTerminé !\e[0m"