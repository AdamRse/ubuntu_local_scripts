#!/bin/bash

# Paramètres
parent_script_absolute="${BASH_SOURCE[$((depth - 1))]}"
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