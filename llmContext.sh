#!/bin/bash
#===============================================================================
# Nom:         llmContext.sh
# Description: Collecte des fichiers d'un projet pour les présenter à un LLM
#              Fonctionne avec un dossier .context et un fichier context-config.json
# Auteur:      Adam Rousselle
# Version:     1.0.1
# Date:        2025-02-27
# Usage:       ./llmContext.sh <chemin_projet> [options]
# Options:     -i, --init   Initialise la structure .context dans le projet
#===============================================================================

# Activation du mode strict pour une meilleure détection d'erreurs
# Commenté pour éviter les arrêts inattendus lors de l'utilisation des globstar
# set -e
# set -o pipefail

# Activer globstar pour utiliser les motifs ** (récursifs)
shopt -s globstar
# Activer nullglob pour que les motifs sans correspondance deviennent des chaînes vides
shopt -s nullglob

#===============================================================================
# CONSTANTES ET VARIABLES GLOBALES
#===============================================================================

# VARIABLES PARAMETRES
readonly PREFIXES=("" "${HOME}/dev" "${HOME}" "${HOME}/dev/g404") # Préfixes de chemin possibles pour le projet
COPY_LOCATION="${HOME}/Téléchargements/Contexte_LLM" # Dossier dans lequel sera copié tous les fichiers de contexte

# Variables globales initialisées avec des valeurs par défaut
declare -a FILES_TO_COLLECT=("**/*")
declare -a FILES_TO_IGNORE=()
INIT_MODE=false
PROJECT_PATH=""

#===============================================================================
# FONCTIONS
#===============================================================================

# Affiche un message d'aide sur l'utilisation du script
show_usage() {
    echo "Usage: $(basename "$0") <chemin_projet> [options]"
    echo "Options:"
    echo "  -i, --init    Initialise la structure .context dans le projet"
    echo "  -h, --help    Affiche cette aide"
}

# Initialise les configurations par défaut selon le type de projet détecté
# Aucun paramètre d'entrée, utilise la variable globale PROJECT_PATH
# Aucune valeur de retour, modifie les variables globales FILES_TO_COLLECT et FILES_TO_IGNORE
set_default_collect_type() {
    if [ -f "${PROJECT_PATH}/artisan" ] && [ -d "${PROJECT_PATH}/app" ]; then # Laravel détecté
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

# Vérifie si un fichier doit être ignoré en le comparant aux motifs d'exclusion
# Paramètres:
#   $1 - Chemin relatif du fichier à vérifier
# Valeur de retour:
#   0 (true) si le fichier doit être ignoré, 1 (false) sinon
should_ignore_file() {
    local rel_path="$1"
    
    # Toujours ignorer le fichier de configuration lui-même
    if [[ "${rel_path}" == ".context/context-config.json" ]]; then
        return 0 # true, ignorer le fichier
    fi
    
    for ignore_pattern in "${FILES_TO_IGNORE[@]}"; do
        # Comparaison avec le motif d'exclusion
        if [[ "${rel_path}" == ${ignore_pattern} ]]; then
            return 0 # true, ignorer le fichier
        fi
    done
    
    return 1 # false, ne pas ignorer le fichier
}

# Copie un fichier vers le répertoire de destination avec le format approprié
# Paramètres:
#   $1 - Chemin complet du fichier à copier
# Aucune valeur de retour
copy_file() {
    local file="$1"
    local rel_path="${file#$PROJECT_PATH/}"
    local filename

    # Vérifier l'existence du fichier source
    if [ ! -f "${file}" ]; then
        echo -e "\e[31mErreur: Le fichier source n'existe pas: ${file}\e[0m"
        return 1
    fi

    # Vérifier l'accès en lecture au fichier source
    if [ ! -r "${file}" ]; then
        echo -e "\e[31mErreur: Permissions insuffisantes pour lire le fichier: ${file}\e[0m"
        return 1
    fi

    # Vérifier si le fichier est vide
    if [ ! -s "${file}" ]; then
        echo -e "\e[33mIgnoré (fichier vide): ${rel_path}\e[0m"
        return 1
    fi
    
    echo -e "\e[32mCopie: ${rel_path}\e[0m"
    # Récupération du nom du fichier sans le chemin
    filename=$(basename "${file}")

    # Si un fichier a le même nom ailleurs dans le projet, on utilisera le chemin relatif pour en faire un nom unique
    if [ -f "${COPY_LOCATION}/${filename}" ]; then
        filename="${rel_path//\//-}"
    fi
    
    # Vérifier l'existence du fichier source
    if [ ! -f "${file}" ]; then
        echo -e "\e[31mErreur: Le fichier source n'existe pas: ${file}\e[0m"
        return 1
    fi
    
    # Vérifier l'accès en lecture au fichier source
    if [ ! -r "${file}" ]; then
        echo -e "\e[31mErreur: Permissions insuffisantes pour lire le fichier: ${file}\e[0m"
        return 1
    fi
    
    if [[ "${rel_path}" == .context/* ]]; then
        # Pour les fichiers du répertoire .context, copie directe sans ajout de commentaire
        cp "${file}" "${COPY_LOCATION}/${filename}" || {
            echo -e "\e[31mErreur lors de la copie du fichier: ${file}\e[0m"
            return 1
        }
    elif [[ "${filename}" == *.blade.php ]]; then
        # Pour les fichiers Blade
        {
            echo -e "{{-- File location in project : ${rel_path} --}}"
            cat "${file}"
        } > "${COPY_LOCATION}/${filename}" || {
            echo -e "\e[31mErreur lors de la copie du fichier Blade: ${file}\e[0m"
            return 1
        }
    elif [[ "${filename}" == *.php ]]; then
        # Pour les fichiers PHP standards
        awk '/<\?/{print;print "// File location in project : '"${rel_path}"'";next}1' "${file}" > "${COPY_LOCATION}/${filename}" || {
            echo -e "\e[31mErreur lors de la copie du fichier PHP: ${file}\e[0m"
            return 1
        }
    elif [[ "${filename}" == *.js ]]; then
        # Pour les fichiers JavaScript
        {
            echo -e "// File location in project : ${rel_path}"
            cat "${file}"
        } > "${COPY_LOCATION}/${filename}" || {
            echo -e "\e[31mErreur lors de la copie du fichier JS: ${file}\e[0m"
            return 1
        }
    elif [[ "${filename}" == *.css ]]; then
        # Pour les fichiers CSS
        {
            echo -e "/*\n* File location in project : ${rel_path}\n*/"
            cat "${file}"
        } > "${COPY_LOCATION}/${filename}" || {
            echo -e "\e[31mErreur lors de la copie du fichier CSS: ${file}\e[0m"
            return 1
        }
    else
        # Pour tous les autres types de fichiers
        {
            echo -e "# File location in project : ${rel_path}"
            cat "${file}"
        } > "${COPY_LOCATION}/${filename}" || {
            echo -e "\e[31mErreur lors de la copie d'un fichier générique: ${file}\e[0m"
            return 1
        }
    fi
    
    return 0
}

# Collecte les fichiers en utilisant les motifs glob
# Aucun paramètre d'entrée, utilise les variables globales
# Aucune valeur de retour
collect_files() {
    # Mémoriser le répertoire de travail actuel
    local current_dir
    current_dir=$(pwd)
    
    # Se déplacer dans le répertoire du projet pour que les motifs glob fonctionnent correctement
    cd "${PROJECT_PATH}" || {
        echo -e "\e[31mErreur: Impossible d'accéder au répertoire du projet: ${PROJECT_PATH}\e[0m"
        return 1
    }
    
    local file_count=0
    local ignored_count=0
    
    # Parcourir tous les motifs à collecter
    for pattern in "${FILES_TO_COLLECT[@]}"; do
        echo -e "-----------\nRecherche avec le motif: ${pattern}"
        
        # Utiliser directement le motif glob de bash
        for file in ${pattern}; do
            # Vérifier si c'est un fichier régulier
            if [[ -f "${file}" ]]; then
                # Vérifier si le fichier doit être ignoré
                if should_ignore_file "${file}"; then
                    echo -e "\e[33mIgnoré: ${file}\e[0m"
                    ((ignored_count++))
                else
                    # Utilisation du chemin relatif tel qu'il est, sans ajouter PROJECT_PATH une seconde fois
                    if copy_file "$(pwd)/${file}"; then
                        ((file_count++))
                    fi
                fi
            fi
        done
    done
    
    echo -e "\e[1;36mStatistiques:\e[0m"
    echo -e "- Fichiers copiés: ${file_count}"
    echo -e "- Fichiers ignorés: ${ignored_count}"
    
    # Revenir au répertoire de travail initial
    cd "${current_dir}" || echo -e "\e[33mAvertissement: Impossible de revenir au répertoire initial: ${current_dir}\e[0m"
}

# Fonction pour charger la configuration depuis le fichier .context/context-config.json
# Aucun paramètre d'entrée, utilise la variable globale PROJECT_PATH
# Valeur de retour:
#   0 si la configuration a été chargée avec succès
#   1 si la configuration par défaut a été utilisée
load_context_config() {
    local config_file="${PROJECT_PATH}/.context/context-config.json"
    
    # Vérification si le fichier de configuration existe
    if [ -f "${config_file}" ]; then
        echo "Fichier de configuration trouvé: ${config_file}"
        
        # Vérifier si jq est installé
        if ! command -v jq >/dev/null 2>&1; then
            echo "Erreur: L'utilitaire 'jq' n'est pas installé mais est requis pour analyser le fichier de configuration."
            echo "Installez-le avec 'sudo apt install jq'."
            exit 1
        fi
        
        # Vérifier que le fichier JSON est valide
        if ! jq empty "${config_file}" 2>/dev/null; then
            echo -e "\e[31mErreur: Le fichier de configuration n'est pas un JSON valide.\e[0m"
            echo "Vérifiez la syntaxe de votre fichier: ${config_file}"
            exit 1
        fi
        
        # Vérifier que la structure est correcte (files_to_collect doit exister)
        if ! jq -e '.files_to_collect' "${config_file}" >/dev/null 2>&1; then
            echo -e "\e[31mErreur: Le fichier de configuration ne contient pas la clé obligatoire 'files_to_collect'.\e[0m"
            echo "Assurez-vous que votre fichier contient au moins un tableau 'files_to_collect'."
            exit 1
        fi
        
        echo "Utilisation du fichier de configuration: ${config_file}"
        
        # Lecture des fichiers à collecter
        mapfile -t FILES_TO_COLLECT < <(jq -r '.files_to_collect[]' "${config_file}")
        
        # Lecture des fichiers à ignorer (si présents)
        if jq -e '.files_to_ignore' "${config_file}" >/dev/null 2>&1; then
            mapfile -t FILES_TO_IGNORE < <(jq -r '.files_to_ignore[]' "${config_file}")
        fi
        
        # On peut aussi charger d'autres configurations si nécessaire
        if jq -e '.copy_location' "${config_file}" >/dev/null 2>&1; then
            COPY_LOCATION=$(jq -r '.copy_location' "${config_file}")
            # Expansion de la variable $HOME si présente
            COPY_LOCATION="${COPY_LOCATION//\$HOME/${HOME}}"
        fi
        
        return 0
    else
        echo "Aucun fichier de configuration trouvé. Utilisation de la configuration par défaut."
        set_default_collect_type
    fi
    return 1
}

# Nouvelle fonction pour initialiser l'architecture .context
# Aucun paramètre d'entrée, utilise les variables globales PROJECT_PATH, FILES_TO_COLLECT et FILES_TO_IGNORE
# Aucune valeur de retour
initialize_context_structure() {
    local context_dir="${PROJECT_PATH}/.context"
    
    echo "Initialisation de la structure .context pour le projet: ${PROJECT_PATH}"
    
    # Création du dossier .context s'il n'existe pas
    if [ ! -d "${context_dir}" ]; then
        echo "Création du dossier .context"
        mkdir -p "${context_dir}" || {
            echo -e "\e[31mErreur: Impossible de créer le dossier .context\e[0m"
            exit 1
        }
    fi
    
    # Création du fichier instructions.txt
    if [ ! -f "${context_dir}/instructions.txt" ]; then
        echo "Création du fichier instructions.txt"
        cat > "${context_dir}/instructions.txt" << EOL
# Instructions pour le contexte LLM
Ce fichier contient des instructions sur la façon dont le code du projet devrait être interprété.
Vous pouvez ajouter ici des informations pertinentes pour le LLM.
EOL
    fi
    
    # Création du fichier objectif.txt
    if [ ! -f "${context_dir}/objectif.txt" ]; then
        echo "Création du fichier objectif.txt"
        cat > "${context_dir}/objectif.txt" << EOL
# Objectif du projet
Décrivez ici l'objectif principal du projet et les fonctionnalités clés.
Ces informations aideront le LLM à comprendre le contexte global.
EOL
    fi
    
    # Création du fichier context-config.json avec les valeurs par défaut
    if [ ! -f "${context_dir}/context-config.json" ]; then
        echo "Création du fichier context-config.json"
        
        # Utilisation d'un heredoc pour une meilleure lisibilité
        {
            echo "{"
            echo "    \"files_to_collect\": ["
            
            # Ajouter chaque pattern de collecte
            for (( i=0; i<${#FILES_TO_COLLECT[@]}; i++ )); do
                if [ $i -eq $(( ${#FILES_TO_COLLECT[@]} - 1 )) ]; then
                    echo "        \"${FILES_TO_COLLECT[$i]}\""
                else
                    echo "        \"${FILES_TO_COLLECT[$i]}\","
                fi
            done
            
            echo "    ],"
            echo "    \"files_to_ignore\": ["
            
            # Ajouter chaque pattern d'ignorance
            for (( i=0; i<${#FILES_TO_IGNORE[@]}; i++ )); do
                if [ $i -eq $(( ${#FILES_TO_IGNORE[@]} - 1 )) ]; then
                    echo "        \"${FILES_TO_IGNORE[$i]}\""
                else
                    echo "        \"${FILES_TO_IGNORE[$i]}\","
                fi
            done
            
            echo "    ],"
            echo "    \"copy_location\": \"${COPY_LOCATION}\""
            echo "}"
        } > "${context_dir}/context-config.json" || {
            echo -e "\e[31mErreur: Impossible de créer le fichier de configuration\e[0m"
            exit 1
        }
    fi
    
    echo -e "\e[1;32mInitialisation terminée !\e[0m"
    echo "Structure .context créée dans: ${context_dir}"
}

# Analyse les arguments de la ligne de commande
# Paramètres: tous les arguments de la ligne de commande ($@)
# Aucune valeur de retour, modifie les variables globales
parse_arguments() {
    # Vérification du nombre d'arguments
    if [ $# -eq 0 ]; then
        show_usage
        exit 1
    fi
    
    # Le premier argument est toujours le nom/chemin du projet
    local path_sent="$1"
    shift
    
    # Nettoyage de path_sent (on enlève les / au début et à la fin)
    path_sent="${path_sent%/}"
    path_sent="${path_sent#/}"
    
    # Recherche du chemin absolu du projet
    for prefix in "${PREFIXES[@]}"; do
        local test_path="${prefix}/${path_sent}"
        if [ -d "${test_path}" ]; then
            PROJECT_PATH="${test_path}"
            break
        fi
    done
    
    if [ -z "${PROJECT_PATH}" ]; then
        echo -e "\e[31mErreur: Impossible de trouver le projet ${path_sent}\e[0m"
        exit 1
    fi
    echo "Projet trouvé : dans ${PROJECT_PATH}"
    
    # Parcourir les arguments restants pour les options
    while [ $# -gt 0 ]; do
        case "$1" in
            -i|--init)
                INIT_MODE=true
                ;;
            -h|--help)
                show_usage
                exit 0
                ;;
            *)
                echo -e "\e[31mOption non reconnue: $1\e[0m"
                show_usage
                exit 1
                ;;
        esac
        shift
    done
}

# Prépare le dossier de destination pour recevoir les fichiers
# Aucun paramètre d'entrée, utilise la variable globale COPY_LOCATION
# Valeur de retour: 0 en cas de succès, 1 en cas d'échec
prepare_destination_folder() {
    # Vérifier si le chemin de destination est valide
    if [ -z "${COPY_LOCATION}" ]; then
        echo -e "\e[31mErreur: Le chemin de destination n'est pas défini\e[0m"
        return 1
    fi
    
    # Si le dossier existe déjà, demander confirmation avant de le nettoyer
    if [ -d "${COPY_LOCATION}" ]; then
        echo "Le répertoire de destination ${COPY_LOCATION} existe déjà."
        echo "Les fichiers existants dans ce répertoire seront supprimés."
        
        # Nettoyage du répertoire de contexte
        rm -rf "${COPY_LOCATION}"/* || {
            echo -e "\e[31mErreur: Impossible de nettoyer le répertoire de destination\e[0m"
            return 1
        }
        echo "Répertoire de destination nettoyé avec succès."
    else
        echo "Création du répertoire de destination ${COPY_LOCATION}"
        mkdir -p "${COPY_LOCATION}" || {
            echo -e "\e[31mErreur: Impossible de créer le répertoire de destination\e[0m"
            return 1
        }
        echo "Répertoire de destination créé avec succès."
    fi
    
    return 0
}

#===============================================================================
# PROGRAMME PRINCIPAL
#===============================================================================

main() {
    # Analyse des arguments de la ligne de commande
    parse_arguments "$@"
    
    # Chargement de la configuration spécifique au projet
    load_context_config
    
    # Si mode d'initialisation, créer la structure .context et quitter
    if [ "${INIT_MODE}" = true ]; then
        echo "Mode initialisation activé"
        initialize_context_structure
        exit 0
    fi
    
    # Préparation du dossier de destination
    if ! prepare_destination_folder; then
        echo -e "\e[31mErreur lors de la préparation du dossier de destination. Arrêt du script.\e[0m"
        exit 1
    fi
    
    # Collecte des fichiers selon les motifs définis
    collect_files
    
    echo -e "\e[1;32m++++++++\nTerminé !\e[0m"
    echo "Les fichiers ont été copiés dans: ${COPY_LOCATION}"
}

# Exécution du programme principal
main "$@"