#!/bin/bash

# fonctions primaires (utilisées par les fonctions utiles)
get_original_script() {
    local depth=${#BASH_SOURCE[@]}
    local original_script="${BASH_SOURCE[$((depth - 1))]}"
    echo "$original_script"
}
timestamp() {
    date +"[%Y/%m/%d %H-%M-%S.%6N]"
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
    parent_script="$(get_original_script)"
    timestamp="$(timestamp)"

    if [ -z "$1" ]; then
        echo "fonction lout() : Aucun message passé." >&2
        return 1
    fi
    if [ -z "$LOG_DIR" ] || [ ! -d "$LOG_DIR" ]; then
        logfile="./logs/$parent_script.log"
    else
        logfile="$LOG_DIR/$parent_script.log"
    fi

    echo "$1"
    echo "$1" >> "$logfile"
    return 0
}
fout() {
    parent_script="$(get_original_script)"
    timestamp="$(timestamp)"

    if [ -z "$1" ]; then
        echo "fonction fout() : Aucun message passé." >&2
        exit 1
    fi
    if [ -z "$LOG_DIR" ] || [ ! -d "$LOG_DIR" ]; then
        logfile="./logs/$parent_script.log"
    else
        logfile="$LOG_DIR/$parent_script.log"
    fi

    echo "$1" >&2
    echo "$1" >> "$logfile"
    exit 1
}
wout() {
    parent_script="$(get_original_script)"
    timestamp="$(timestamp)"

    if [ -z "$1" ]; then
        echo "fonction wout() : Aucun message passé." >&2
        exit 1
    fi
    if [ -z "$LOG_DIR" ] || [ ! -d "$LOG_DIR" ]; then
        logfile="./logs/$parent_script.log"
    else
        logfile="$LOG_DIR/$parent_script.log"
    fi

    echo "$1" >&2
    echo "$1" >> "$logfile"
}