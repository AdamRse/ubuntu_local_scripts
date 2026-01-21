#!/bin/bash

# Paramètres
# Obtenir le chemin réel du script parent (même via lien symbolique)
if [ -L "${BASH_SOURCE[$((depth - 1))]}" ]; then
    parent_script_absolute=$(readlink -f "${BASH_SOURCE[$((depth - 1))]}")
else
    parent_script_absolute="${BASH_SOURCE[$((depth - 1))]}"
fi
parent_script_name=$(basename $parent_script_absolute)
parent_script_path=$(dirname $parent_script_absolute)
timestamp=$(date +"[%Y/%m/%d %H-%M-%S.%6N]")
# Logs activés ou non, conversion en booléen
if [ "$LOG_ENABLE" == "true" ] || [ "$LOG_ENABLE" == "1" ]; then
    LOG_ENABLE=true
else
    LOG_ENABLE=false
fi

# Obtenir le répertoire des logs
if $LOG_ENABLE; then
    if [ -d "$LOG_DIR" ]; then
        logfile="$LOG_DIR/$parent_script_name.log"
    elif [ -d "$parent_script_path/$LOG_DIR" ]; then
        logfile="$parent_script_path/$LOG_DIR/$parent_script_name.log"
    else
        logfile="$parent_script_path/logs/$parent_script_name.log"
    fi
fi

# $1 : mode     : relative|absolute
# $2 : path     : 
# return string : path nettoyé
clean_path_variable(){
    local mode="${1}"
    local path="${2}"
    if [ -n "${path}" ]; then
        local relative="relative"
        local absolute="absolute"
        path=$(echo "$path" | tr -s '/')
        if [ "${mode}" = "${relative}" ]; then
            path="${path#/}"
            path="${path%/}"
        elif [ "${mode}" = "${absolute}" ]; then
            path="/${path#/}"
            path="${path%/}"
        else
            eout "clean_path_variable() : Erreur, mode non conforme passé en 1er paramètre. Attendu : '${relative}' ou '${absolute}'"
        fi
    fi
    echo "$path"
}

# Utilisable avec pipe
# $1 : dir  : chemin absolu du répertoire
# return bool
is_empty_dir(){
    local dir="${1-$(cat)}"
    [ -z "${dir}" ] && eout "is_empty_dir() : Aucun paramètre donné. Passer le chemin absolu d'un répertoire à tester en paramètre."
    [ -d "${dir}" ] || return 0

    if [ -z "$(find "$dir" -mindepth 1 -maxdepth 1 -print -quit)" ]; then
        return 0
    else
        return 1
    fi
}


# Normaliser les chemins relatifs (enlever le slash de début et de fin pour être fusionnable)
trim_slashes() {
    local p="$1"
    # enlever un slash leading s'il y en a un
    if [[ "$p" == /* ]]; then
        p="${p#/}"
    fi
    # enlever un slash trailing s'il y en a un
    if [[ "$p" == */ ]]; then
        p="${p%/}"
    fi
    echo "$p"
}

# Fonction pour désactiver la veille (mais pas l'écran)
disable_sleep() {
    if command -v xdg-screensaver &> /dev/null; then
        echo "Désactivation de la veille système..."
        # Obtenir l'ID de la fenêtre active
        local window_id
        window_id=$(xdotool getactivewindow 2>/dev/null)
        
        if [ -n "$window_id" ]; then
            xdg-screensaver suspend "$window_id"
            echo "La veille est désactivée (l'écran peut toujours s'éteindre)"
            return 0
        else
            echo "Erreur: Impossible d'obtenir l'ID de fenêtre"
            echo "Installez xdotool: sudo apt install xdotool"
            return 1
        fi
    else
        echo "Erreur: xdg-screensaver n'est pas installé"
        echo "Installez-le avec: sudo apt install xdg-utils"
        return 1
    fi
}
#Réactiver la mise en veille
enable_sleep() {
    if command -v xdg-screensaver &> /dev/null; then
        echo "Réactivation de la veille système..."
        # Obtenir l'ID de la fenêtre active
        local window_id
        window_id=$(xdotool getactivewindow 2>/dev/null)
        
        if [ -n "$window_id" ]; then
            xdg-screensaver resume "$window_id"
            echo "La veille est réactivée"
            return 0
        else
            echo "Erreur: Impossible d'obtenir l'ID de fenêtre"
            echo "Installez xdotool: sudo apt install xdotool"
            return 1
        fi
    else
        echo "Erreur: xdg-screensaver n'est pas installé"
        return 1
    fi
}