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

# Fonctions utiles
ask_yn () {
    if [ -z "$1" ]; then
        echo -e "fonction ask_yn() : Aucun paramètre passé" >&2
        exit 1
    fi

    while true; do
    read -n 1 -p "$1 (o/n)" response
    echo ""
    # Vérification de la réponse
    if [[ $response == "o" || $response == "O" ]]; then
        return 0
    elif [[ $response == "n" || $response == "N" ]]; then
        return 1
    else
        echo -e "'$response' : Réponse invalide. Veuillez entrer 'o' (Oui) ou 'n' (Non)."
    fi
done
}

lout() {
    if [ -z "$1" ]; then
        echo "fonction lout() : Aucun message passé." >&2
        return 1
    fi

    echo "$1"
    if $LOG_ENABLE; then
        echo "$timestamp $1" >> "$logfile"
    fi
    return 0
}
fout() {
    if [ -z "$1" ]; then
        echo "fonction fout() : Aucun message passé." >&2
        exit 1
    fi

    echo "Erreur : $1" >&2
    if $LOG_ENABLE; then
        echo "$timestamp ERROR : $1" >> "$logfile"
    fi
    exit 1
}
wout() {
    if [ -z "$1" ]; then
        echo "fonction wout() : Aucun message passé." >&2
        exit 1
    fi

    echo "Attention : $1" >&2
    if $LOG_ENABLE; then
        echo "$timestamp WARNING : $1" >> "$logfile"
    fi
}