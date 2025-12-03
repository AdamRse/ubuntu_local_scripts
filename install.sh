#!/bin/bash

############### OPTIONS
restart_after=false

############### VARS, Utilisées dans le script
home_folder=""
user_name=""
user_group=""
is_github_auth=false
is_dev_architecture=false
is_gaming=false
is_set_github=false

############### CONST
RED="\e[31m"
YELLOW="\e[33m"
ENDCOLOR="\e[0m"

############### FUNTIONS
ask_yn () {
    if [ -z "$1" ]; then
        echo "fonction ask_yn() : Aucun paramètre passé" >&2
        exit 1
    fi

    while true; do
        read -n 1 -p "$1 (o/n)" response
        # Vérification de la réponse
        if [[ $response == "o" || $response == "O" ]]; then
            echo ""
            return 0
        elif [[ $response == "n" || $response == "N" ]]; then
            echo ""
            return 1
        else
            echo ""
            echo -e "'$response' : Réponse invalide. Veuillez entrer 'o' (Oui) ou 'n' (Non).\n"
        fi
    done
}

lout() {
    if [ -z "$1" ]; then
        echo -e "${RED}fonction lout() : Aucun message passé.${ENDCOLOR}" >&2
        return 1
    fi

    echo -e "$1"
    return 0
}
fout() {
    if [ -z "$1" ]; then
        echo -e "${RED}fonction fout() : Aucun message passé.${ENDCOLOR}" >&2
        exit 1
    fi

    echo -e "${RED}Erreur : $1${ENDCOLOR}" >&2
    exit 1
}
wout() {
    if [ -z "$1" ]; then
        echo -e "${RED}fonction wout() : Aucun message passé.${ENDCOLOR}" >&2
        exit 1
    fi

    echo -e "${YELLOW}Attention : $1${ENDCOLOR}" >&2
}

############### CHECKS
user_name="$(logname)"
user_group="$(id -gn ${user_name})"
home_folder="$(getent passwd ${user_name} | cut -d: -f6)"

[ -z "$user_name" ] && fout "Nom d'utilisateur non trouvé"
[ -z "$user_group" ] && fout "Groupe principal de l'utilisateur ${$user_name} non trouvé"
[ -z "$home_folder" ] && [ -d "$home_folder" ] && fout "Dossier home de l'utilisateur ${$user_name} non trouvé"

lout "\n\nTest de connexion à github\n"

ssh -T git@github.com
github_status=$?
if [ $github_status -eq 1 ]; then
    lout "Authentification GitHub détectée"
    is_github_auth=true
else
    wout "Aucune connexion github via SSH détectée"
fi

############### ASK OPTIONS
ask_yn "Installer l'architecture '/home/dev' pour les projets github ?" && is_dev_architecture=true
ask_yn "Installer un environement de jeu vidéo ?" && is_gaming=true
ask_yn "Si vous souhaitez paramétrer une connexion github, ajoutez vos clés SSH dans '$home_folder/.ssh' avec le nom $user_name@github, validez ensuite votre réponse ici :\
\nParamétrer github maintenant ?" && is_set_github=true


############### MAIN