#!/bin/bash

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